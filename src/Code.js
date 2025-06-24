/**
 * @OnlyCurrentDoc
 */

// --- GLOBAL CONSTANTS ---
const PROPERTIES = PropertiesService.getDocumentProperties();

/**
 * Runs when the add-on is first installed or the document is opened.
 * Creates a single menu item to open the management dialog.
 * @param {Object} e The event parameter for a simple onOpen/onInstall trigger.
 */
function onOpen(e) {
  FormApp.getUi()
    .createMenu('Event Sign-up')
    .addItem('Manage', 'showDialog')
    .addToUi();
}

/**
 * Shows the main management dialog in the Google Form UI.
 */
function showDialog() {
  const htmlOutput = HtmlService.createTemplateFromFile('Dialog')
    .evaluate()
    .setWidth(1024)
    .setHeight(768);
  FormApp.getUi().showModalDialog(htmlOutput, 'Event Sign-up Manager');
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/**
 * Fetches all necessary data to populate the dialog UI in one call.
 * @returns {Object} A comprehensive status object for the dialog.
 */
function getDialogData() {
  try {
    const properties = PropertiesService.getDocumentProperties();
    const calendarId = properties.getProperty('calendarId');
    const eventId = properties.getProperty('eventId');
    const form = FormApp.getActiveForm();

    if (calendarId && eventId) {
      const { calendarName, eventTitle, eventTime, error } = getLinkedEventDetails(calendarId, eventId);
      if (error) {
        return { isConfigured: false, allCalendars: getCalendars(), errorMessage: error };
      }
      return {
        isConfigured: true,
        linkedCalendarName: calendarName,
        linkedEventTitle: eventTitle,
        linkedEventTime: eventTime,
        formCollectsEmails: form.collectsEmail()
      };
    } else {
      return { isConfigured: false, allCalendars: getCalendars() };
    }
  } catch (e) {
    Logger.log(`Error in getDialogData: ${e.toString()}`);
    return { isConfigured: false, errorMessage: `Server error: ${e.message}` };
  }
}

/**
 * Retrieves details for a specific calendar event.
 * @param {string} calendarId The ID of the calendar.
 * @param {string} eventId The ID of the event.
 * @returns {Object} An object containing the calendar name, event title, and event time.
 */
function getLinkedEventDetails(calendarId, eventId) {
  try {
    const calendar = CalendarApp.getCalendarById(calendarId);
    if (!calendar) return { error: 'Linked calendar not found.' };

    const event = calendar.getEventById(eventId);
    if (!event) return { error: 'Linked event not found.' };

    const startTime = event.getStartTime();
    const endTime = event.getEndTime();
    const timeFormat = { hour: '2-digit', minute: '2-digit', hour12: false };
    const dateFormat = { weekday: 'long', month: 'long', day: 'numeric' };

    return {
      calendarName: calendar.getName(),
      eventTitle: event.getTitle(),
      eventTime: `${startTime.toLocaleDateString(undefined, dateFormat)}, ${startTime.toLocaleTimeString([], timeFormat)} - ${endTime.toLocaleTimeString([], timeFormat)}`
    };
  } catch (e) {
    return { error: `Could not retrieve event details: ${e.message}` };
  }
}

/**
 * Sets the form's state for accepting responses.
 * @param {boolean} isEnabled True to enable, false to disable.
 * @returns {boolean} The new state.
 */
function setAutomationStatus(isEnabled) {
  FormApp.getActiveForm().setAcceptingResponses(isEnabled);
  return isEnabled;
}

/**
 * Deletes the 'onFormSubmit' trigger and all stored properties.
 */
function resetConfiguration() {
  try {
    const form = FormApp.getActiveForm();
    const functionName = 'addAttendeeOnSubmit';
    const triggers = ScriptApp.getUserTriggers(form);
    for (const trigger of triggers) {
      if (trigger.getHandlerFunction() === functionName) {
        ScriptApp.deleteTrigger(trigger);
      }
    }
    PROPERTIES.deleteAllProperties();
    Logger.log("Configuration and trigger have been reset.");
    return getDialogData();
  } catch (e) {
    console.error('Error resetting configuration:', e);
    return { isConfigured: false, errorMessage: `Server error while resetting: ${e.message}` };
  }
}

/**
 * Fetches all calendars the user has access to.
 * @returns {Array<Object>} An array of calendar objects with name and id.
 */
function getCalendars() {
  try {
    const allCalendars = CalendarApp.getAllCalendars();
    const defaultCalendar = CalendarApp.getDefaultCalendar();
    const defaultCalId = defaultCalendar.getId();

    const calendarList = allCalendars.map(cal => ({
      id: cal.getId(),
      name: cal.getName()
    }));

    // Find the default calendar in the list
    const defaultCalIndex = calendarList.findIndex(cal => cal.id === defaultCalId);

    // If found, move it to the top of the list
    if (defaultCalIndex > -1) {
      const [defaultCal] = calendarList.splice(defaultCalIndex, 1);
      calendarList.unshift(defaultCal);
    }

    return calendarList;
  } catch (error) {
    Logger.log(`Error in getCalendars: ${error.toString()}`);
    return [];
  }
}

/**
 * Searches for events in a specific calendar.
 * @param {string} calendarId The ID of the calendar to search.
 * @param {string} searchQuery The text to search for in event titles.
 * @returns {Array<Object>} An array of event objects with details.
 */
function getEvents(calendarId, searchQuery) {
  if (!calendarId) return [];
  try {
    const calendar = CalendarApp.getCalendarById(calendarId);
    if (!calendar) return [];

    const startTime = new Date();
    const endTime = new Date();
    endTime.setFullYear(endTime.getFullYear() + 1);

    const events = calendar.getEvents(startTime, endTime, { search: searchQuery });
    return events.map(event => ({
      id: event.getId(),
      title: event.getTitle(),
      startTime: event.getStartTime().toISOString(),
      endTime: event.getEndTime().toISOString()
    }));
  } catch (error) {
    Logger.log(`Error in getEvents: ${error.toString()}`);
    return [];
  }
}

/**
 * Saves the selected configuration and sets up the trigger.
 * @param {string} calendarId The ID of the selected calendar.
 * @param {string} eventId The ID of the selected event.
 * @returns {Object} A success or error message object.
 */
function saveConfiguration(calendarId, eventId) {
  try {
    const properties = PropertiesService.getDocumentProperties();
    properties.setProperties({
      'calendarId': calendarId,
      'eventId': eventId,
    });
    console.log(`Configuration saved: Calendar ID: ${calendarId}, Event ID: ${eventId}`);
    createOnFormSubmitTrigger();
    return getDialogData(); // Return the full, updated data object
  } catch (e) {
    console.error('Error saving configuration:', e);
    return { errorMessage: `Error saving configuration: ${e.message}` };
  }
}

/**
 * Creates or updates the onFormSubmit trigger for the add-on.
 */
function createOnFormSubmitTrigger() {
  const form = FormApp.getActiveForm();
  const functionName = 'addAttendeeOnSubmit';
  const triggers = ScriptApp.getUserTriggers(form);
  for (const trigger of triggers) {
    if (trigger.getHandlerFunction() === functionName) {
      ScriptApp.deleteTrigger(trigger);
    }
  }
  ScriptApp.newTrigger(functionName)
    .forForm(form)
    .onFormSubmit()
    .create();
  Logger.log("Form submit trigger created/updated.");
}

/**
 * The core function that runs on form submission.
 * @param {Object} e The event object passed by the onFormSubmit trigger.
 */
function addAttendeeOnSubmit(e) {
  const config = PROPERTIES.getProperties();
  const CALENDAR_ID = config.calendarId;
  const EVENT_ID = config.eventId;

  if (!CALENDAR_ID || !EVENT_ID) {
    Logger.log("Configuration not found.");
    return;
  }
  try {
    const respondentEmail = e.response.getRespondentEmail();
    if (!respondentEmail) {
      Logger.log("Respondent email not found.");
      return;
    }
    const calendar = CalendarApp.getCalendarById(CALENDAR_ID);
    if (!calendar) {
      Logger.log(`Calendar not found: ${CALENDAR_ID}`);
      return;
    }
    const event = calendar.getEventById(EVENT_ID);
    if (!event) {
      Logger.log(`Event not found: ${EVENT_ID}`);
      return;
    }
    event.addGuest(respondentEmail);
    Logger.log(`Added guest: ${respondentEmail} to event: "${event.getTitle()}".`);
  } catch (error) {
    Logger.log(`Error in addAttendeeOnSubmit: ${error.toString()}`);
  }
}
