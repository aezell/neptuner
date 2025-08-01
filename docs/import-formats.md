# Import & Migration Formats Guide

This guide explains the supported import formats for migrating your productivity data to Neptuner.

## Supported Import Sources

### 1. Todoist Export

**File Format:** JSON  
**How to Export:**
1. Go to Todoist Settings → Backups
2. Click "Create backup" to generate a JSON export
3. Download the backup file

**Supported Data:**
- Tasks with titles and descriptions
- Priority levels (mapped to cosmic priorities)
- Project organization
- Completion status
- Due dates
- Labels

**Cosmic Priority Mapping:**
- Priority 4 (Highest) → `matters_10_years`
- Priority 3 → `matters_10_days`  
- Priority 2 → `matters_10_days`
- Priority 1 (Lowest) → `matters_to_nobody`

### 2. Notion Database Export

**File Format:** JSON database export  
**How to Export:**
1. Open your Notion task/habit database
2. Click the "..." menu → Export
3. Select "JSON" format and export
4. Upload the exported JSON file

**Supported Properties:**
- **Tasks:** Name/Title, Description, Priority, Due Date, Done/Completed
- **Habits:** Name/Habit, Description, Frequency, Category

**Priority Mapping:**
- High/Urgent/Critical → `matters_10_years`
- Medium/Normal → `matters_10_days`
- Low/Minor → `matters_to_nobody`

**Habit Category Mapping:**
- Health/Fitness/Wellness → `basic_human_function`
- Work/Productivity/Career → `self_improvement_theater`
- Learning/Education → `actually_useful`

### 3. Apple Reminders

**File Format:** JSON (converted from plist)  
**How to Export:**
1. Use a third-party export tool to export Apple Reminders
2. Convert to JSON format if possible
3. Upload the exported file

**Supported Data:**
- Reminder titles and notes
- Priority levels (0-9 scale mapped to cosmic priorities)
- Due dates
- Completion status

### 4. Generic CSV

**File Format:** CSV with headers  
**Required Columns:**
- `title` or `Title` - Task title
- `description` or `Description` - Task description (optional)
- `priority` or `Priority` - Priority level (optional)
- `due_date` or `Due Date` - Due date in ISO format (optional)
- `completed` or `Completed` - Completion status (optional)

**Priority Values:**
- High/Urgent/Critical/1 → `matters_10_years`
- Medium/Normal/2 → `matters_10_days`
- Low/Minor/3 → `matters_to_nobody`

**Example CSV:**
```csv
title,description,priority,due_date,completed
"Complete project proposal","Draft the Q4 project proposal",high,2024-12-15,false
"Buy groceries","Weekly grocery shopping",low,,true
"Team meeting","Weekly team sync",medium,2024-08-01,false
```

### 5. Generic JSON (Habits)

**File Format:** JSON array  
**Required Fields:**
- `name` - Habit name
- `description` - Habit description (optional)
- `frequency` - daily/weekly/monthly (optional, defaults to daily)
- `category` - Habit category (optional)

**Example JSON:**
```json
[
  {
    "name": "Morning meditation",
    "description": "10 minutes of mindfulness",
    "frequency": "daily",
    "category": "wellness"
  },
  {
    "name": "Read technical articles",
    "description": "Stay updated with industry trends",
    "frequency": "weekly",
    "category": "learning"
  }
]
```

## Import Process

1. **Select Source** - Choose your productivity app from the supported list
2. **Upload File** - Upload your exported data file
3. **Preview & Confirm** - Review what will be imported with cosmic insights
4. **Migration Complete** - Enjoy your newly integrated productivity cosmos!

## Cosmic Philosophy

Remember: All imported productivity data undergoes cosmic transformation. Your tasks will be analyzed through the lens of existential significance, and achievements will be celebrated with appropriate cosmic skepticism.

The universe expands to accommodate your newly imported productivity consciousness, transforming digital busy work into stellar productivity insights.

## Need Help?

If you encounter issues with importing:
1. Verify your export file format matches the requirements
2. Check that required columns/fields are present
3. Ensure file size is under 10MB
4. Try the preview function to see what will be imported

The cosmic import wizard provides detailed feedback at each step to guide your productivity migration journey.