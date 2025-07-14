# Forms Event Sign-up Addon

A Google Workspace Add-on that automates event sign-ups by connecting Google Forms to Google Calendar events. When someone submits a form, they are automatically added as a guest to the specified calendar event.

You can install it from https://workspace.google.com/marketplace/app/event_signup/1094030587053.

## Features

- **Automatic Guest Addition**: Form respondents become calendar event guests
- **Easy Configuration**: Simple setup through sidebar interface
- **Real-time Status**: Monitor automation status and form acceptance
- **Error Handling**: Graceful handling of missing calendars/events
- **Responsive UI**: Optimized for Google Forms sidebar

## Architecture

- **Backend**: Google Apps Script with Form and Calendar API integration
- **Frontend**: HTML/CSS/JavaScript sidebar interface
- **Storage**: Document properties for configuration persistence
- **Automation**: Form submission triggers for guest management

## Prerequisites

- Node.js (v16 or higher)
- Google account with access to Google Apps Script
- Google Forms and Google Calendar access

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/forms-event-sign-up-addon.git
cd forms-event-sign-up-addon
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Authenticate with Google

```bash
npm run login
```

This will open a browser window for Google authentication. Follow the prompts to authorize clasp.

### 5. Create Google Apps Script Project

```bash
npm run create
```

This creates a new Google Apps Script project and updates the `.clasp.json` file with the project ID.

### 6. Push Initial Code

```bash
npm run push
```

This pushes your local code to the Google Apps Script project.

## Development Workflow

### Local Development

1. **Edit Code**: Make changes to files in the `src/` directory
2. **Test Locally**: Use your preferred editor/IDE
3. **Commit Changes**: Use Git for version control
4. **Push to Google Apps Script**: Deploy changes

### Available Scripts

```bash
# Authentication and setup
npm run login          # Login to Google Apps Script
npm run create         # Create new Google Apps Script project
npm run setup          # Login and create project

# Development
npm run push           # Push local changes to Google Apps Script
npm run pull           # Pull changes from Google Apps Script
npm run open           # Open Google Apps Script project in browser
npm run watch          # Watch for changes and auto-push

# Deployment
npm run deploy         # Deploy new version
npm run versions       # List deployed versions
npm run logs           # View execution logs

# Sync
npm run sync           # Bidirectional sync (pull then push)
```

### Deployment Scripts

The project includes two deployment scripts in the `scripts/` directory:

#### `scripts/deploy.sh`
Full deployment workflow with version management.

```bash
# Full deployment with timestamp
./scripts/deploy.sh

# Deploy with custom description
./scripts/deploy.sh "v1.2.3 - Bug fixes"

# Pull changes only
./scripts/deploy.sh pull

# Show deployment status
./scripts/deploy.sh status
```

#### `scripts/sync.sh`
Bidirectional synchronization between local and Google Apps Script.

```bash
# Bidirectional sync (default)
./scripts/sync.sh

# Pull from Google Apps Script
./scripts/sync.sh pull

# Push to Google Apps Script
./scripts/sync.sh push

# Force sync (overwrite remote with local)
./scripts/sync.sh force-local

# Show sync status
./scripts/sync.sh status
```

## Project Structure

```
forms-event-sign-up-addon/
├── .clasp.json              # Clasp configuration
├── .gitignore               # Git ignore rules
├── package.json             # Node.js dependencies and scripts
├── README.md               # This file
├── src/                    # Source files
│   ├── Code.js            # Main Google Apps Script code
│   ├── Sidebar.html       # Sidebar interface
│   └── appsscript.json    # Apps Script manifest
└── scripts/               # Build and deployment scripts
    ├── deploy.sh          # Deployment script
    └── sync.sh            # Sync script
```

## Configuration

### Google Apps Script Manifest (`src/appsscript.json`)

The manifest file defines:
- **OAuth Scopes**: Required permissions for Forms, Calendar, UI and Script APIs
- **Runtime**: V8 JavaScript runtime
- **Timezone**: Default timezone for the project

### Clasp Configuration (`.clasp.json`)

Links your local project to the Google Apps Script project:
- **scriptId**: Your Google Apps Script project ID
- **rootDir**: Source directory (`src/`)

## Usage

### Setting Up the Add-on

1. **Open Google Forms**: Create or open a Google Form
2. **Install Add-on**: Install the add-on from Google Workspace Marketplace
3. **Open Sidebar**: Click "Add-ons" → "Event Sign-up" → "Manage"
4. **Configure Event**: Select calendar and event in the sidebar
5. **Enable Automation**: Toggle the master control to enable sign-ups

### How It Works

1. **Form Submission**: When someone submits the form
2. **Trigger Activation**: The add-on automatically runs
3. **Email Extraction**: Respondent's email is extracted from the form
4. **Guest Addition**: Email is added as guest to the configured calendar event
5. **Logging**: Operation is logged for audit purposes

## Development Guidelines

### Code Standards

- Follow the cursor rules in `.cursor/rules/`
- Use proper error handling and logging
- Implement comprehensive testing
- Follow Google Apps Script best practices

### Git Workflow

1. **Feature Branches**: Create feature branches for new development
2. **Commit Messages**: Use conventional commit format
3. **Pull Requests**: Submit PRs for review before merging
4. **Version Tags**: Tag releases with semantic versioning

### Testing

- Test in Google Apps Script environment
- Validate form-calendar integration
- Test error scenarios and edge cases
- Verify UI behavior in different states

## Troubleshooting

### Common Issues

#### Clasp Authentication
```bash
# If clasp login fails, try:
npm run logout
npm run login
```

#### Permission Errors
- Ensure you have edit access to the Google Apps Script project
- Check that OAuth scopes are properly configured
- Verify Google Calendar permissions

#### Sync Conflicts
```bash
# If you have sync conflicts:
./scripts/sync.sh force-local    # Overwrite remote with local
# OR
./scripts/sync.sh force-remote   # Overwrite local with remote
```

### Debugging

- Use `npm run logs` to view execution logs
- Check Google Apps Script execution logs in the browser
- Use `console.log()` in frontend JavaScript for debugging
- Monitor Google Apps Script quota usage

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Google Apps Script documentation
- Open an issue on GitHub

## Changelog

### v1.0.0
- Initial release
- Basic form-to-calendar automation
- Sidebar configuration interface
- Error handling and logging 
