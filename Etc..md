# Pipeline Utilities (pipeline_utils.py)

## Overview

The `pipeline_utils.py` module provides a comprehensive set of utility functions for interacting with the OCS (Open Cloud Services) pipeline system. These utilities facilitate job submission, monitoring, and management for alignment and post-QC processing of biological samples.

The module is organized into several functional groups to maintain separation of concerns and improve code readability:

1. **Configuration Functions**: Load and manage pipeline configuration
2. **Utility Functions**: General helper functions
3. **Script Execution Functions**: Create and run bash scripts
4. **Command Generation Functions**: Generate pipeline command strings
5. **Job Submission Functions**: Submit jobs to the OCS system
6. **Job Status Functions**: Check and process job statuses
7. **Job Management Functions**: Manage running, completed, and failed jobs
8. **Job Polling and Queue Functions**: Retrieve and update job information

## Dependencies

- Django ORM (for database interaction)
- Python standard libraries: json, os, subprocess, yaml, logging, etc.
- Database models: Alignment, PostQC, Metadata, Main, RunningJob, CompletedJob, FailedJob
- OCS CLI tools (for interacting with the cloud infrastructure)

## Integration Map

The functions in this module are used by various frontend and backend components:

### Backend Components:
- **pipeline.py**: Main controller for pipeline views and API endpoints
- **job_monitor.py**: Handles job monitoring views and queue management
- **core/views.py**: Provides queue management API endpoints

### Frontend Components:
- **job-monitor.js**: JavaScript for job status monitoring UI
- **queue-management.js**: JavaScript for queue management UI
- **pipeline-local-data.js**: Manages local browser storage of sample data
- **pipeline-submit-modal.js**: Handles submission modals and command generation
- **pipeline-final-modal.js**: Shows final commands and executes submissions

## Component Interaction Map

This section provides detailed tracing of how functions in `pipeline_utils.py` are used throughout the application:

### Dashboard Flow
- **HTML**: `dashboard.html` (main entry point)
- **View**: `PipelineDashboardView` (in `pipeline.py`)
  - Calls `load_pipeline_config()` → loads references and chemistry settings
  - Calls `count_running_jobs()` → displays active job counts
- **JavaScript**: 
  - `pipeline-dashboard.js` → handles sample selection/submission buttons
  - `pipeline-local-data.js` → manages browser localStorage for selected samples
  - `pipeline-submit-modal.js` → generates and validates commands
  - `pipeline-final-modal.js` → displays final commands and submits jobs

### Frontend → Backend Interaction Flow

#### Sample Selection and Storage
1. **OCS Browser page** → User selects samples 
   - `ocs-browser.js` → calls `saveSelectedToPipeline()`
   - `pipeline-local-data.js` → stores samples in localStorage
   - Sample data format stored: fastq_name, organism_common_name, batch_name_from_vendor, etc.

2. **Dashboard page** → User views selected samples
   - `dashboard.html` → loads on page navigation
   - `pipeline-local-data.js` → `reinitialize()` retrieves stored samples
   - `rebuildSamplesTable()` → displays samples in dashboard table

#### Command Generation Flow 
1. **User clicks "Submit Selected"** → `pipeline-dashboard.js` event handler
2. **Submission Modal opens** → `pipeline-submit-modal.js:openModal()`
3. **Frontend determines workflow type**:
   ```javascript
   // pipeline-submit-modal.js
   determineWorkflow(sample) {
     // Check batch_name_from_vendor for MTX pattern
     const batchName = sample.batch_name_from_vendor.toUpperCase();
     if (batchName.startsWith('MTX') || batchName.includes('ATX')) {
       return 'MTX';
     }
     return 'RTX'; // Default
   }
   ```
   - This is equivalent to backend `determine_workflow()` in pipeline_utils.py
   
4. **Frontend generates commands**:
   ```javascript
   // pipeline-submit-modal.js
   generateAlignmentCommand(sample) {
     const workflow = this.determineWorkflow(sample);
     const reference = this.getReference(sample.organism_common_name);
     
     if (workflow === 'MTX') {
       // MTX command generation (similar to create_mtx_alignment_command)
     } else {
       // RTX command generation (similar to create_rtx_alignment_command)
       // Including chemistry lookup via this.getChemistry()
     }
   }
   ```
   - Frontend equivalents of `create_mtx_alignment_command()` and `create_rtx_alignment_command()`

5. **User configures options** → Auto-proceed toggle, reference selection
   ```javascript
   // pipeline-submit-modal.js
   handleAutoProceedToggle() {
     // Sets up auto-proceed workflow by marking PostQC jobs as PENDING
   }
   ```

#### Job Submission Flow
1. **User clicks "Execute"** → `pipeline-final-modal.js:executeSubmission()`
2. **Commands sent to backend**:
   ```javascript
   // pipeline-final-modal.js
   fetch('/api/queue/import/', {
     method: 'POST',
     body: JSON.stringify({ queue })
   })
   ```
   - Queue format includes alignment/postqc commands and status ("Ready" or "PENDING")

3. **Backend processes submission**:
   ```python
   # core/views.py
   def import_queue(request):
     # Creates entries in queue_jobs table
     # Marks auto-proceed PostQC jobs as "PENDING"
   ```

4. **Backend queue processing**:
   ```python
   # core/views.py
   def process_queue(request):
     # Finds "Ready" jobs in queue_jobs table
     # Calls submit_sample_from_dashboard() for each job
   ```

5. **Backend job submission**:
   ```python
   # pipeline_utils.py
   def submit_sample_from_dashboard(sample):
     # Determines workflow via determine_workflow()
     # Generates command via create_mtx/rtx_alignment_command()
     # Creates bash script and executes OCS submission
   ```

### Job Monitoring Flow

#### UI Interaction
1. **Job Monitor Page** → `job_monitor.html`
2. **JavaScript timer** → `job-monitor.js:startAutoRefresh()`
   ```javascript
   // job-monitor.js
   startAutoRefresh() {
     this.autoRefreshInterval = setInterval(() => {
       this.refreshJobs();
     }, this.autoRefreshTime);
   }
   ```

3. **API Calls for data**:
   ```javascript
   // job-monitor.js
   refreshJobs() {
     fetch('/api/pipeline/get-job-data/')
       .then(response => response.json())
       .then(data => this.updateJobTables(data));
   }
   ```

4. **Backend generates job data**:
   ```python
   # pipeline.py
   def get_job_data(request):
     # Calls count_running_jobs()
     # Queries running_jobs/completed_jobs tables
     return JsonResponse({'job_counts': job_counts, 'running_jobs': running_jobs})
   ```

#### Status Checking
1. **User clicks "Check Status"** → `job-monitor.js:checkJobStatus()`
   ```javascript
   // job-monitor.js
   checkJobStatus(demandId) {
     fetch(`/api/pipeline/check-job-status/${demandId}/`, {
       method: 'POST'
     })
   }
   ```

2. **Backend checks job status**:
   ```python
   # pipeline.py
   def check_job_status(request, demand_id):
     result = process_job_status_update(demand_id)
     return JsonResponse(result)
   ```

3. **Status processing**:
   ```python
   # pipeline_utils.py
   def process_job_status_update(demand_id):
     status_result = check_job_status(demand_id)
     # If completed/failed: move_job_to_destination_table()
     # If alignment completed: process_auto_proceed_jobs()
   ```

4. **Response updates UI**:
   ```javascript
   // job-monitor.js
   .then(data => {
     this.updateJobUI(data.job_status, demandId);
     this.showToastNotification(`Job status: ${data.job_status}`);
   });
   ```

#### Stopping Jobs
1. **User clicks "Stop Job"** → `job-monitor.js:stopJob()`
   ```javascript
   // job-monitor.js
   stopJob(demandId) {
     fetch(`/api/pipeline/stop-alignment/${demandId}/`, {
       method: 'POST'
     })
   }
   ```

2. **Backend stops job**:
   ```python
   # pipeline.py
   def stop_alignment(request, demand_id):
     result = stop_job(demand_id)
     update_result = process_job_status_update(demand_id)
     return JsonResponse(result)
   ```

3. **Job is terminated**:
   ```python
   # pipeline_utils.py
   def stop_job(demand_id):
     # Executes OCS command to stop job
     # Returns result to caller
   ```

### Queue Management Flow

#### UI Interaction
1. **Queue Management Page** → `queue_management.html`
2. **JavaScript timer** → `queue-management.js:startAutoProcessing()`
   ```javascript
   // queue-management.js
   startAutoProcessing() {
     this.autoProcessInterval = setInterval(() => {
       if (!this.queuePaused) {
         this.processQueue();
       }
     }, this.autoProcessTime);
   }
   ```

3. **Process queue function**:
   ```javascript
   // queue-management.js
   processQueue() {
     fetch('/api/queue/process/', {
       method: 'POST'
     })
   }
   ```

4. **Backend processes queue**:
   ```python
   # core/views.py
   def process_queue(request):
     # Checks max concurrent jobs via count_running_jobs()
     # Finds next "Ready" job from queue_jobs
     job_result = submit_sample_from_dashboard(sample_data)
     # On success, removes from queue_jobs, adds to running_jobs
   ```

### Auto-Proceed Workflow Detailed Flow

1. **User enables Auto-Proceed toggle**:
   ```javascript
   // pipeline-submit-modal.js:
   handleAutoProceedToggle() {
     this.autoProceedEnabled = !this.autoProceedEnabled;
     // Updates UI and sample data
   }
   ```

2. **Final modal marks PostQC as PENDING**:
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // For each command with auto-proceed enabled:
     if (cmd.autoToggle === true) {
       status = 'PENDING'; // Will wait for alignment
     } else {
       status = 'Ready';   // Will process immediately
     }
   }
   ```

3. **Backend queue import**:
   ```python
   # core/views.py:import_queue
   # Creates database records with respective statuses
   queue_job = QueueJobs(
     fastq_name=fastq_name,
     alignment_command=alignment_command,
     postqc_command=postqc_command,
     status=status  # "Ready" or "PENDING"
   )
   ```

4. **Alignment job completion**:
   ```python
   # pipeline_utils.py:process_job_status_update
   if job_status == 'COMPLETED' and demand_type == 'align':
     process_auto_proceed_jobs(fastq_name)
   ```

5. **Auto-proceed detection**:
   ```python
   # pipeline_utils.py:process_auto_proceed_jobs
   # Finds PENDING postQC jobs for same fastq_name
   pending_jobs = QueueJobs.objects.filter(
     fastq_name=fastq_name,
     postqc_command__isnull=False,
     status='PENDING'
   )
   # Updates status to "Ready"
   pending_jobs.update(status='Ready')
   ```

6. **Next queue processing cycle** → picks up newly Ready job

### Failed Job Handling Flow

1. **Failed Jobs Page** → `failed_jobs.html` displays jobs from failed_jobs table
2. **User clicks "Retry"** → Form submission with fastq_name and job_type
   ```javascript
   // failed_jobs.html (jQuery)
   $.ajax({
     url: '/api/pipeline/retry-failed-job/',
     type: 'POST',
     data: JSON.stringify({
       fastq_name: fastqName,
       job_type: jobType
     })
   })
   ```

3. **Backend retries job**:
   ```python
   # pipeline.py:PipelineApiView.retry_failed_job
   # Retrieves sample metadata
   # Calls submit_sample_from_dashboard()
   # Increments retry_count
   # Removes from failed_jobs
   ```

4. **UI Updated** → Job removed from failed jobs list, user notified

## Detailed JavaScript to Backend Function Mapping

| JavaScript Component | Frontend Function | Backend API Endpoint | Backend Utility Function |
|---------------------|-------------------|----------------------|-------------------------|
| pipeline-dashboard.js | handleSubmitSelected() | - | - |
| pipeline-submit-modal.js | determineWorkflow() | - | determine_workflow() |
| pipeline-submit-modal.js | getReference() | /api/pipeline/config | get_reference_name() |
| pipeline-submit-modal.js | getChemistry() | /api/pipeline/config | get_chemistry() |
| pipeline-submit-modal.js | generateAlignmentCommand() | - | create_mtx/rtx_alignment_command() |
| pipeline-final-modal.js | executeSubmission() | /api/queue/import/ | - |
| pipeline-local-data.js | storeSelectedSample() | - | - |
| job-monitor.js | refreshJobs() | /api/pipeline/get-job-data/ | count_running_jobs() |
| job-monitor.js | checkJobStatus() | /api/pipeline/check-job-status/ | check_job_status(), process_job_status_update() |
| job-monitor.js | stopJob() | /api/pipeline/stop-alignment/ | stop_job() |
| job-monitor.js | refreshAllJobStatuses() | /api/pipeline/update_all_jobs/ | update_all_running_jobs() |
| queue-management.js | processQueue() | /api/queue/process/ | submit_sample_from_dashboard() |
| queue-management.js | fetchQueueData() | /api/queue/get_data/ | get_ocs_running_jobs() |

## API Endpoints and Backend Function Call Stack

### Job Submission (/api/queue/import/ → /api/queue/process/)
```
1. pipeline-final-modal.js:executeSubmission() → POST /api/queue/import/
2. core/views.py:import_queue() → Creates queue_jobs entries
3. queue-management.js:processQueue() → POST /api/queue/process/
4. core/views.py:process_queue() → Finds "Ready" jobs
5. pipeline_utils.py:submit_sample_from_dashboard() → Submits to OCS
   ├→ pipeline_utils.py:determine_workflow()
   ├→ pipeline_utils.py:create_mtx/rtx_alignment_command()
   ├→ pipeline_utils.py:create_bash_script()
   └→ pipeline_utils.py:run_bash_script()
```

### Job Status Checking (/api/pipeline/check-job-status/)
```
1. job-monitor.js:checkJobStatus() → POST /api/pipeline/check-job-status/{demand_id}/
2. pipeline.py:PipelineApiView.check_job_status() → Processes request
3. pipeline_utils.py:process_job_status_update() → Checks current status
   ├→ pipeline_utils.py:check_job_status()
   ├→ pipeline_utils.py:move_job_to_destination_table() (if completed/failed)
   └→ pipeline_utils.py:process_auto_proceed_jobs() (if alignment completed)
```

### Job Monitoring (/api/pipeline/get-job-data/ and /api/pipeline/update_all_jobs/)
```
1. job-monitor.js:refreshJobs() → GET /api/pipeline/get-job-data/
2. pipeline.py:PipelineApiView.get_job_data() → Retrieves job data
   └→ pipeline_utils.py:count_running_jobs()

1. job-monitor.js:refreshAllJobStatuses() → POST /api/pipeline/update_all_jobs/
2. pipeline.py:PipelineApiView.update_all_jobs() → Updates all jobs
   └→ pipeline_utils.py:update_all_running_jobs()
      └→ pipeline_utils.py:process_job_status_update() (for each job)
```

### Stop Job (/api/pipeline/stop-alignment/)
```
1. job-monitor.js:stopJob() → POST /api/pipeline/stop-alignment/{demand_id}/
2. pipeline.py:PipelineApiView.stop_alignment() → Stops job
   ├→ pipeline_utils.py:stop_job()
   └→ pipeline_utils.py:process_job_status_update()
```

### Failed Job Retry (/api/pipeline/retry-failed-job/)
```
1. failed_jobs.html form submission → POST /api/pipeline/retry-failed-job/
2. pipeline.py:PipelineApiView.retry_failed_job() → Retries job
   └→ pipeline_utils.py:submit_sample_from_dashboard()
```

## Data Flow Diagrams for Key Workflows

### Sample Selection to Submission Flow
```
User selects samples in OCS Browser
↓
ocs-browser.js:saveSelectedToPipeline()
↓
pipeline-local-data.js → localStorage
↓
User navigates to Pipeline Dashboard
↓
pipeline-local-data.js:reinitialize() → Populates dashboard table
↓
User clicks "Submit Selected"
↓
pipeline-submit-modal.js → Opens submission modal
↓
User configures options (workflow, reference, auto-proceed)
↓
pipeline-final-modal.js → Shows final commands
↓
User clicks "Execute"
↓
pipeline-final-modal.js:executeSubmission() → Sends to API
↓
core/views.py:import_queue() → Stores in queue_jobs table
↓
queue-management.js:processQueue() → Processes queue
↓
core/views.py:process_queue() → Finds next job
↓
pipeline_utils.py:submit_sample_from_dashboard() → Submits to OCS
↓
Job runs in OCS cloud
```

### Auto-Proceed Workflow Flow
```
User enables Auto-Proceed toggle in submission modal
↓
pipeline-final-modal.js → Sends with PENDING status for PostQC
↓
core/views.py:import_queue() → Creates two entries in queue_jobs:
  ├→ Alignment job with status="Ready"
  └→ PostQC job with status="PENDING"
↓
Queue processing → Submit alignment job
↓
Job runs in OCS until completion
↓
job-monitor.js timer → Triggers status check
↓
update_all_running_jobs() → Checks all jobs
↓
process_job_status_update() → Detects completed alignment
↓
process_auto_proceed_jobs() → Finds PENDING PostQC job
↓
Updates status from "PENDING" to "Ready"
↓
Next queue processing → Picks up PostQC job
↓
submit_sample_from_dashboard() → Submits PostQC
```

### Job Status Update Loop
```
JobMonitorView loaded
↓
job-monitor.js:startAutoRefresh() → Sets refresh timer
↓                                           ↑
job-monitor.js:refreshJobs()                |
↓                                           |
GET /api/pipeline/get-job-data/             |
↓                                           |
PipelineApiView.get_job_data()              |
↓                                           |
count_running_jobs() + database queries     |
↓                                           |
Return data to frontend                     |
↓                                           |
job-monitor.js → Updates UI tables          |
↓                                           |
Wait for next interval ----------------------+
```

### Failed Job Retry Flow
```
User views failed_jobs.html
↓
User clicks "Retry" button
↓
$.ajax POST to /api/pipeline/retry-failed-job/
↓
pipeline.py:PipelineApiView.retry_failed_job()
↓
Retrieve sample metadata
↓
submit_sample_from_dashboard()
↓
Generate command and submit to OCS
↓
Update database:
  ├→ Increment retry_count
  ├→ Update status to "SUBMITTED"
  ├→ Remove from failed_jobs
  └→ Add to queue_jobs or running_jobs
↓
Return status to frontend
↓
UI updated (row removed)
```

## Function Groups

### Configuration Functions

```python
def load_pipeline_config():
    """Load pipeline configuration from yaml file"""
```

**Used by:**
- `PipelineDashboardView._get_pipeline_config()` in pipeline.py
- `get_pipeline_config_view()` in pipeline.py
- `get_reference_name()` and `get_chemistry()` in pipeline_utils.py

**Function Usage Tracing:**
```
File: viewer/features/pipeline/pipeline.py
- PipelineDashboardView._get_pipeline_config() → load_pipeline_config()
  ↪ Cached in Django's cache system with key 'pipeline_config'
  ↪ Used in dashboard.html template to populate reference/chemistry dropdowns

File: viewer/features/api/api.py
- pipeline_config() → load_pipeline_config()
  ↪ Accessed by pipeline-submit-modal.js via AJAX call to /api/pipeline/config

File: viewer/utils/pipeline_utils.py
- get_reference_name() → load_pipeline_config()
- get_chemistry() → load_pipeline_config()
```

**Workflow:**
```
Browser Request → PipelineDashboardView → load_pipeline_config() → Cache Configuration → Return to Template
```

### Utility Functions

```python
def is_ingest_complete(fastq_name):
    """Check if ingest is complete for a given fastq name"""

def determine_workflow(batch_name_from_vendor):
    """Determine workflow based on batch name from vendor"""

def get_reference_name(organism_common_name):
    """Get reference name for an organism"""

def get_chemistry(library_prep_method):
    """Get chemistry value for a library prep method"""
```

**Used by:**
- `submit_sample_from_dashboard()` in pipeline_utils.py
- `submit_samples()` API endpoint in pipeline.py
- Frontend workflow determination in pipeline-submit-modal.js

**Function Usage Tracing:**
```
is_ingest_complete():
  File: viewer/utils/pipeline_utils.py
  - submit_sample_from_dashboard() → is_ingest_complete()
  
  File: viewer/features/pipeline/pipeline.py
  - submit_samples() → is_ingest_complete()
    ↪ Skips samples with incomplete ingest status

determine_workflow():
  File: viewer/utils/pipeline_utils.py
  - submit_sample_from_dashboard() → determine_workflow()
  - get_ocs_running_jobs() → determine_workflow()
  
  File: viewer/features/pipeline/pipeline.py
  - submit_samples() → determine_workflow()
  
  File: viewer/static/viewer/js/pipeline-submit-modal.js
  - determineWorkflow() (JavaScript equivalent)
    ↪ Uses similar logic to backend determine_workflow()

get_reference_name():
  File: viewer/utils/pipeline_utils.py
  - create_mtx_alignment_command() → get_reference_name()
  - create_rtx_alignment_command() → get_reference_name()
  
  File: viewer/static/viewer/js/pipeline-submit-modal.js
  - getReference() (JavaScript equivalent)

get_chemistry():
  File: viewer/utils/pipeline_utils.py
  - create_rtx_alignment_command() → get_chemistry()
  
  File: viewer/static/viewer/js/pipeline-submit-modal.js
  - getChemistry() (JavaScript equivalent)
```

**Workflow:**
```
Sample Selection → determine_workflow() → Command Generation → Sample Submission
```

### Script Execution Functions

```python
def create_bash_script(commands, script_name='temp_script.sh'):
    """Create a temporary bash script with the given commands"""

def run_bash_script(script_path):
    """Run a bash script and return its output"""
```

**Used by:**
- `submit_sample_from_dashboard()` in pipeline_utils.py
- All OCS command execution functions

**Function Usage Tracing:**
```
File: viewer/utils/pipeline_utils.py
- submit_sample_from_dashboard() → create_bash_script() → run_bash_script()
- check_job_status() → create_bash_script() → run_bash_script()
- stop_job() → create_bash_script() → run_bash_script()
- count_running_jobs() → create_bash_script() → run_bash_script()
- get_ocs_running_jobs() → create_bash_script() → run_bash_script()
```

**Workflow:**
```
Command Generation → create_bash_script() → run_bash_script() → Parse Result → Return Status
```

### Command Generation Functions

```python
def create_mtx_alignment_command(sample):
    """Create MTX alignment command for a sample"""

def create_rtx_alignment_command(sample):
    """Create RTX alignment command for a sample"""
```

**Used by:**
- `submit_sample_from_dashboard()` in pipeline_utils.py
- `submit_samples()` API endpoint in pipeline.py
- Emulated by frontend in pipeline-submit-modal.js

**Function Usage Tracing:**
```
create_mtx_alignment_command():
  File: viewer/utils/pipeline_utils.py
  - submit_sample_from_dashboard() → create_mtx_alignment_command()
  
  File: viewer/features/pipeline/pipeline.py
  - submit_samples() → create_mtx_alignment_command()
  
  File: viewer/static/viewer/js/pipeline-submit-modal.js
  - generateAlignmentCommand() (handles MTX workflow with similar logic)
    ↪ Used when creating commands in submission modal

create_rtx_alignment_command():
  File: viewer/utils/pipeline_utils.py
  - submit_sample_from_dashboard() → create_rtx_alignment_command()
  
  File: viewer/features/pipeline/pipeline.py
  - submit_samples() → create_rtx_alignment_command()
  
  File: viewer/static/viewer/js/pipeline-submit-modal.js
  - generateAlignmentCommand() (handles RTX workflow with similar logic)
```

**Workflow:**
```
Sample Data → determine_workflow() → 
  ├─ if MTX → create_mtx_alignment_command() 
  └─ if RTX → create_rtx_alignment_command()
→ Command String → Submit to OCS
```

### Job Submission Functions

```python
def submit_sample_from_dashboard(sample):
    """Submit a sample for processing and return the result"""
```

**Used by:**
- `PipelineApiView.retry_failed_job()` in pipeline.py
- `submit_samples()` API endpoint in pipeline.py
- `process_queue()` API endpoint in core/views.py
- Triggered by pipeline-submit-modal.js through API calls

**Function Usage Tracing:**
```
File: viewer/features/pipeline/pipeline.py
- submit_samples() → submit_sample_from_dashboard()
  ↪ Called via API endpoint /api/pipeline/submit-samples/
  ↪ Used by pipeline-final-modal.js when user clicks "Execute"

- PipelineApiView.retry_failed_job() → submit_sample_from_dashboard()
  ↪ Called via API endpoint /api/pipeline/retry-failed-job/
  ↪ Used from failed_jobs.html when retrying failed jobs

File: viewer/core/views.py
- process_queue() → submit_sample_from_dashboard()
  ↪ Called via API endpoint /api/queue/process/
  ↪ Used by queue-management.js to process jobs automatically
```

**Workflow:**
```
UI Selection → pipeline-submit-modal.js → POST API Request → 
    submit_samples() API → submit_sample_from_dashboard() → 
    OCS Submission → Response → Database Update → UI Update
```

### Job Status Functions

```python
def count_running_jobs():
    """Count the number of running alignment and post-align jobs from OCS"""
```

**Used by:**
- `PipelineDashboardView._get_job_data()` in pipeline.py
- `JobMonitorView._get_fresh_job_data()` in job_monitor.py
- `process_queue()` in core/views.py
- Accessed by job-monitor.js through API calls

**Function Usage Tracing:**
```
File: viewer/features/pipeline/pipeline.py
- PipelineDashboardView._get_job_data() → count_running_jobs()
  ↪ Displayed on dashboard.html for job statistics

File: viewer/features/job_monitoring/job_monitor.py
- JobMonitorView._get_fresh_job_data() → count_running_jobs()
  ↪ Displayed on job_monitor.html for monitoring running jobs

File: viewer/core/views.py
- process_queue() → count_running_jobs()
  ↪ Used to check available capacity before processing queue items

File: viewer/static/viewer/js/job-monitor.js
- refreshJobs() → API call → PipelineApiView.get_job_data() → count_running_jobs()
  ↪ Updates UI with current job counts at regular intervals
```

**Workflow:**
```
UI Timer → job-monitor.js → AJAX Request → 
    PipelineApiView.get_job_data() → count_running_jobs() → 
    Return Counts → Update UI Badges and Tables
```

### Job Management Functions

```python
def check_job_status(demand_id):
    """Check the status of a job with retry logic"""

def stop_job(demand_id):
    """Stop a job (alignment or post-QC)"""

def move_job_to_destination_table(fastq_name, demand_id, status, demand_type, start_time=None, end_time=None):
    """Move a job from running_jobs to either completed_jobs or failed_jobs"""

def process_auto_proceed_jobs(fastq_name):
    """Process auto-proceed jobs when alignment completes successfully"""

def process_job_status_update(demand_id):
    """Process job status updates based on a given demand_id"""
```

**Used by:**
- `PipelineApiView.check_alignment_status()` and `stop_alignment()` in pipeline.py
- `update_all_running_jobs()` in pipeline_utils.py
- Triggered by job-monitor.js through API calls
- Used by auto-proceed workflow when alignments complete

**Function Usage Tracing:**
```
check_job_status():
  File: viewer/utils/pipeline_utils.py
  - process_job_status_update() → check_job_status()
  - update_all_running_jobs() → process_job_status_update() → check_job_status()
  
  File: viewer/features/pipeline/pipeline.py
  - PipelineApiView.check_alignment_status() → check_job_status()
  - PipelineApiView.check_job_status() → check_job_status()
    ↪ Called by job-monitor.js when user clicks "Check Status"

stop_job():
  File: viewer/features/pipeline/pipeline.py
  - PipelineApiView.stop_alignment() → stop_job()
    ↪ Called by job-monitor.js when user clicks "Stop Job"
    ↪ Accessible via button in job_monitor.html

move_job_to_destination_table():
  File: viewer/utils/pipeline_utils.py
  - process_job_status_update() → move_job_to_destination_table()
    ↪ Moves jobs between running_jobs, completed_jobs, failed_jobs tables
    ↪ Updates status in Main table to reflect job completion

process_auto_proceed_jobs():
  File: viewer/utils/pipeline_utils.py
  - process_job_status_update() → process_auto_proceed_jobs()
    ↪ Called when alignment job completes successfully
    ↪ Updates PENDING post-QC jobs to Ready status

process_job_status_update():
  File: viewer/utils/pipeline_utils.py
  - update_all_running_jobs() → process_job_status_update()
  
  File: viewer/features/pipeline/pipeline.py
  - PipelineApiView.check_job_status() → process_job_status_update()
  - PipelineApiView.stop_alignment() → process_job_status_update()
```

**Auto-Proceed Workflow:**
```
1. UI Submission → pipeline-final-modal.js → Set PostQC Status = "PENDING" → Store in queue_jobs
   - File: viewer/static/viewer/js/pipeline-final-modal.js
   - Method: executeSubmission() → sets PENDING status
   - API: /api/queue/import/ → core/views.py:import_queue()

2. Alignment Job → Completes Successfully → process_job_status_update() → 
   - File: viewer/utils/pipeline_utils.py
   - Method: process_job_status_update() → detects COMPLETED status

3. process_auto_proceed_jobs() → Find PENDING PostQC Jobs for Same FASTQ →
   - File: viewer/utils/pipeline_utils.py
   - Searches queue_jobs table for PENDING status with matching fastq_name

4. Update Status from "PENDING" to "Ready" → Queue Processing Starts PostQC Job
   - Updates status in queue_jobs table
   - Next queue processing cycle picks up the now-Ready job
```

**Job Status Update Workflow:**
```
UI Check Status → job-monitor.js → API Call → 
    PipelineApiView.check_job_status() → process_job_status_update() → 
    check_job_status() → OCS Status Check → 
    move_job_to_destination_table() → Database Update → UI Refresh
```

### Job Polling and Queue Functions

```python
def update_all_running_jobs():
    """Update status of all running jobs in the database"""

def get_ocs_running_jobs():
    """Get data for samples in the processing queue"""
```

**Used by:**
- `PipelineApiView.update_all_jobs()` in pipeline.py
- `JobMonitorView._update_jobs_async()` in job_monitor.py
- Triggered by queue-management.js through API calls

**Function Usage Tracing:**
```
update_all_running_jobs():
  File: viewer/features/pipeline/pipeline.py
  - PipelineApiView.update_all_jobs() → update_all_running_jobs()
    ↪ Called via API endpoint /api/pipeline/update_all_jobs/
    ↪ Used by job-monitor.js "Update All" button
  
  File: viewer/features/job_monitoring/job_monitor.py
  - JobMonitorView._update_jobs_async() → update_all_running_jobs()
    ↪ Called in background thread for automatic updates
    ↪ Triggered by auto-refresh in job_monitor.html

get_ocs_running_jobs():
  File: viewer/features/pipeline/pipeline.py
  - PipelineApiView.get_queue_data() → get_ocs_running_jobs()
    ↪ Called via API endpoint /api/pipeline/get-queue-data/
    ↪ Used by job-monitor.js to display queue information
```

**Queue Management Workflow:**
```
1. UI Queue Page → queue-management.js → Auto-timer → 
   - File: viewer/static/viewer/js/queue-management.js
   - Timer method: startAutoProcessing(), processQueue()
   
2. API Call → process_queue() → 
   - File: viewer/core/views.py
   - Endpoint: /api/queue/process/
   
3. Check Status of Jobs → submit_sample_from_dashboard() → 
   - File: viewer/core/views.py → viewer/utils/pipeline_utils.py
   
4. Process Next Ready Job → Update Database → UI Refresh
   - Updates queue_jobs, running_jobs tables
   - Refreshes UI via queue-management.js

Auto-Proceed Control Flow:
Queue Item Status = "Ready" → Process Immediately
  - File: viewer/core/views.py:process_queue() → submits immediately
Queue Item Status = "PENDING" → Wait for Alignment Completion → Auto-Update to "Ready"
  - File: viewer/utils/pipeline_utils.py:process_auto_proceed_jobs()
```

## Application Workflow Diagrams

### Complete Sample Processing Workflow

1. **Sample Selection & Submission:**
   ```
   OCS Browser (ocs-browser.html, ocs-browser.js)
   ↓
   Select samples for processing
   ↓
   Store in browser localStorage via pipeline-local-data.js
   ↓
   Navigate to Pipeline Dashboard (dashboard.html)
   ↓
   Pipeline Dashboard loads samples from localStorage
   ↓
   User clicks "Submit Selected" button (pipeline-dashboard.js)
   ↓
   Submission Modal opens (pipeline-submit-modal.js)
   ↓
   User configures submission options
   ↓
   Final Review Modal (pipeline-final-modal.js)
   ↓
   User clicks "Execute"
   ↓
   API call to /api/queue/import/ (core/views.py:import_queue)
   ↓
   Jobs added to queue_jobs table (with "Ready" or "PENDING" status)
   ```

2. **Queue Processing:**
   ```
   Queue Management Page (queue_management.html)
   ↓
   Auto-processing timer in queue-management.js
   ↓
   API call to /api/queue/process/ (core/views.py:process_queue)
   ↓
   Process finds "Ready" jobs in queue_jobs table
   ↓
   For each "Ready" job:
      ↓
      Generate command with create_mtx_alignment_command() or create_rtx_alignment_command()
      ↓
      submit_sample_from_dashboard() → OCS job submission
      ↓
      Move to running_jobs table
      ↓
      Remove from queue_jobs table
   ```

3. **Job Monitoring:**
   ```
   Job Monitor Page (job_monitor.html, job-monitor.js)
   ↓
   Auto-refresh timer
   ↓
   API call to /api/pipeline/get-job-data/ (PipelineApiView.get_job_data)
   ↓
   Backend calls count_running_jobs() and queries running_jobs/completed_jobs tables
   ↓
   UI tables updated with latest job statuses
   ```

4. **Job Status Updates:**
   ```
   Background process in JobMonitorView._update_jobs_async()
   ↓
   Calls update_all_running_jobs()
   ↓
   For each running job:
      ↓
      process_job_status_update(demand_id)
      ↓
      check_job_status(demand_id) → checks OCS status
      ↓
      If completed/failed/aborted → move_job_to_destination_table()
      ↓
      If alignment completed successfully → process_auto_proceed_jobs()
         ↓
         Update any PENDING post-QC jobs to "Ready" status
   ```

5. **Failed Job Handling:**
   ```
   Failed Jobs Page (failed_jobs.html)
   ↓
   Display jobs from failed_jobs table
   ↓
   User clicks "Retry" button
   ↓
   API call to /api/pipeline/retry-failed-job/ (PipelineApiView.retry_failed_job)
   ↓
   submit_sample_from_dashboard() → retry submission
   ↓
   Move from failed_jobs to running_jobs or queue_jobs
   ```

## UI Component Integration

This section provides detailed tracing of how frontend UI components and event handlers interact with backend functions in `pipeline_utils.py`.

### Frontend → Backend Function Call Map

| Frontend Component | UI Event | JavaScript Function | API Endpoint | Backend Function | 
|-------------------|----------|---------------------|--------------|------------------|
| job-monitor.js | Click "Refresh" button | refreshJobs() | /api/pipeline/get-job-data/ | count_running_jobs() |
| job-monitor.js | Click "Check Status" | checkJobStatus() | /api/pipeline/check-job-status/ | check_job_status() |
| job-monitor.js | Click "Stop Job" | stopJob() | /api/pipeline/stop-alignment/ | stop_job() |
| job-monitor.js | Auto-refresh timer | autoRefreshInterval | /api/pipeline/update_all_jobs/ | update_all_running_jobs() |
| queue-management.js | Auto-process timer | processQueue() | /api/queue/process/ | submit_sample_from_dashboard() |
| queue-management.js | Click "Process Queue" | processQueue() | /api/queue/process/ | submit_sample_from_dashboard() |
| pipeline-submit-modal.js | Click "Next" | handleSubmission() | (prepares commands) | - |
| pipeline-final-modal.js | Click "Execute" | executeSubmission() | /api/queue/import/ | - |
| pipeline-local-data.js | Click "Submit Samples" | handleSampleSubmission() | /api/pipeline/submit-samples/ | submit_sample_from_dashboard() |

### HTML Element → JavaScript Handler Map

| HTML File | Element ID | Event | Handler File | Handler Function |
|-----------|------------|-------|--------------|------------------|
| job_monitor.html | refreshNowBtn | click | job-monitor.js | refreshNowBtn.addEventListener() |
| job_monitor.html | autoRefreshToggle | change | job-monitor.js | autoRefreshToggle.addEventListener() |
| job_monitor.html | check-status-btn | click | job-monitor.js | checkJobStatus() |
| job_monitor.html | stop-job-btn | click | job-monitor.js | stopJob() |
| queue_management.html | process-queue-btn | click | queue-management.js | processQueue() |
| queue_management.html | pause-queue-btn | click | queue-management.js | toggleQueuePause() |
| failed_jobs.html | retry-failed-job | click | - | PipelineApiView.retry_failed_job() |
| dashboard.html | submit-action-btn | click | pipeline-dashboard.js | addEventListener() |

### UI Event Sequence Diagrams

#### Job Status Checking Flow

```
User (job_monitor.html) → Click "Check Status" button
↓
job-monitor.js:checkJobStatus()
↓
fetch('/api/pipeline/check-job-status/{demand_id}/')
↓
PipelineApiView.check_job_status()
↓
process_job_status_update()
↓
check_job_status()
↓
OCS Status Check (via run_bash_script)
↓
Response to frontend
↓
job-monitor.js:showToastNotification()
↓
job-monitor.js updates UI element classes
```

#### Sample Submission Flow

```
User (dashboard.html) → Click "Submit Selected" button
↓
pipeline-dashboard.js event handler
↓
pipeline-submit-modal.js opens submission modal
↓
User configures submission options
↓
User clicks "Next" button
↓
pipeline-submit-modal.js:handleSubmission()
↓
pipeline-final-modal.js shows final commands
↓
User clicks "Execute"
↓
pipeline-final-modal.js:executeSubmission()
↓
fetch('/api/queue/import/')
↓
core/views.py:import_queue()
↓
Jobs added to queue_jobs table
↓
Queue processing begins (on next cycle)
```

#### Auto-Proceed Workflow Detailed Flow

```
User enables Auto-Proceed toggle in pipeline-submit-modal.js
↓
pipeline-final-modal.js:executeSubmission() marks PostQC with "PENDING" status
↓
fetch('/api/queue/import/')
↓
core/views.py:import_queue()
↓
core/views.py:process_queue() creates two entries:
  ├→ Alignment job with status="Ready"
  └→ PostQC job with status="PENDING" (waits for alignment)
↓
Queue auto-processing via queue-management.js:processQueue()
↓
fetch('/api/queue/process/')
↓
core/views.py:process_queue() processes only "Ready" jobs
↓
submit_sample_from_dashboard() submits alignment to OCS
↓
Job runs in OCS until completion
↓
Background job_monitor.js:autoRefreshInterval triggers status check
↓
update_all_running_jobs() checks all running jobs
↓
process_job_status_update() detects completed alignment
↓
process_auto_proceed_jobs() finds PENDING PostQC job for the same FASTQ
↓
Updates PostQC job from "PENDING" to "Ready"
↓
Next queue processing cycle picks up newly Ready PostQC job
↓
submit_sample_from_dashboard() submits PostQC to OCS
```

#### Job Status Monitoring Loop

```
JobMonitorView.__init__() creates page context
↓
job-monitor.js initializes with autoRefreshInterval
↓                                             ↑
job-monitor.js:refreshJobs()                  |
↓                                             |
fetch('/api/pipeline/get-job-data/')          |
↓                                             |
PipelineApiView.get_job_data()                |
↓                                             |
count_running_jobs() and database queries     |
↓                                             |
Return data to frontend                       |
↓                                             |
job-monitor.js updates UI tables and badges   |
↓                                             |
Wait for next interval ----------------------→|
```

### Frontend Component Details

#### job-monitor.js

This JavaScript file is responsible for the job monitoring interface. Key features:

1. **Automatic Refresh**: Sets up intervals to refresh job data automatically
   ```javascript
   // job-monitor.js
   startAutoRefresh() {
     this.autoRefreshInterval = setInterval(() => {
       this.refreshJobs(false);
     }, this.autoRefreshTime);
   }
   ```

2. **Manual Refresh**: Handles user-triggered refresh of job data
   ```javascript
   // job-monitor.js
   refreshJobs(showSuccessToast = false) {
     // Uses fetch() to call /api/pipeline/get-job-data/
     // This triggers count_running_jobs() on the backend
   }
   ```

3. **Status Checking**: Provides UI for checking individual job status
   ```javascript
   // job-monitor.js
   checkJobStatus(demandId) {
     // Uses fetch() to call /api/pipeline/check-job-status/{demandId}/
     // This triggers check_job_status() on the backend
   }
   ```

4. **Job Stopping**: Allows users to stop running jobs
   ```javascript
   // job-monitor.js
   stopJob(demandId) {
     // Uses fetch() to call /api/pipeline/stop-alignment/{demandId}/
     // This triggers stop_job() on the backend
   }
   ```

#### queue-management.js

This JavaScript file handles the queue management interface. Key features:

1. **Queue Fetching**: Retrieves queue data from the server
   ```javascript
   // queue-management.js
   fetchQueueData() {
     // Uses fetch() to call /api/queue/get_data/
     // Displays queue items with pagination
   }
   ```

2. **Auto Processing**: Sets up automatic processing of queued jobs
   ```javascript
   // queue-management.js
   startAutoProcessing() {
     // Sets up timer to call processQueue() automatically
   }
   
   processQueue() {
     // Uses fetch() to call /api/queue/process/
     // This triggers submit_sample_from_dashboard() for Ready jobs
   }
   ```

3. **Queue Control**: Provides UI for pausing/resuming queue processing
   ```javascript
   // queue-management.js
   toggleQueuePause() {
     // Pauses or resumes automatic queue processing
   }
   ```

#### pipeline-submit-modal.js

This JavaScript file handles the submission modal interface. Key features:

1. **Command Generation**: Creates commands based on selected options
   ```javascript
   // pipeline-submit-modal.js
   generateAlignmentCommand(sample) {
     // Frontend equivalent of create_mtx_alignment_command/create_rtx_alignment_command
   }
   ```

2. **Workflow Determination**: Identifies workflow type based on sample data
   ```javascript
   // pipeline-submit-modal.js
   determineWorkflow(sample, options = {}) {
     // Frontend equivalent of determine_workflow()
   }
   ```

3. **Reference/Chemistry Selection**: Provides dropdowns for reference and chemistry
   ```javascript
   // pipeline-submit-modal.js
   getReference(organism) {
     // Frontend equivalent of get_reference_name()
   }
   
   getChemistry(libraryPrep) {
     // Frontend equivalent of get_chemistry()
   }
   ```

#### pipeline-final-modal.js

This JavaScript file handles the final review and execution interface. Key features:

1. **Command Display**: Shows final commands for user review
   ```javascript
   // pipeline-final-modal.js
   show(data) {
     // Displays alignment and post-QC commands for review
   }
   ```

2. **Job Submission**: Submits commands to the queue for processing
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // Uses fetch() to call /api/queue/import/
     // Creates entries in queue_jobs table
   }
   ```

3. **Auto-Proceed Setup**: Handles setting up auto-proceed workflow
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // If auto-proceed enabled, marks PostQC jobs with PENDING status
   }
   ```

### HTML View Templates

#### dashboard.html

The dashboard template displays the main pipeline dashboard with:
- Sample selection table
- Submit button that triggers the submission modal
- Job statistics powered by `count_running_jobs()`

#### job_monitor.html

The job monitor template displays:
- Running jobs table
- Completed jobs table
- Job status counts
- Auto-refresh toggle
- Refresh button
- Check status and stop buttons for individual jobs

#### queue_management.html

The queue management template displays:
- Queue items table
- Process queue button
- Pause/resume queue button
- Auto-processing settings
- Queue statistics

#### failed_jobs.html

The failed jobs template displays:
- Failed jobs table with retry and cancel options
- Failure details
- Retry buttons that trigger `PipelineApiView.retry_failed_job()`

### Database Tables and Models Integration

The following database models are essential to the pipeline system:

1. **RunningJob**: Stores currently running jobs
   - Used by `process_job_status_update()` to track job status
   - Updated by `move_job_to_destination_table()`

2. **CompletedJob**: Stores successfully completed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in job_monitor.html

3. **FailedJob**: Stores failed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in failed_jobs.html

4. **QueueJobs**: Stores jobs waiting to be processed
   - Created by `pipeline-final-modal.js:executeSubmission()`
   - Processed by `process_queue()`
   - Updated by `process_auto_proceed_jobs()`

## Function-Level Call Tracing

This section provides detailed tracing of how each function in `pipeline_utils.py` is used across the application, documenting the exact file paths and call stacks.

### Configuration Functions

#### `load_pipeline_config()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._get_pipeline_config()`
   ```python
   def _get_pipeline_config(self):
       config_cache_key = 'pipeline_config'
       config = cache.get(config_cache_key)
       if config is None:
           config = load_pipeline_config()  # FUNCTION CALL HERE
           cache.set(config_cache_key, config, timeout=PIPELINE_CONFIG_CACHE_TIMEOUT)
   ```

2. `viewer/utils/pipeline_utils.py:get_reference_name()`
   ```python
   def get_reference_name(organism_common_name):
       config = load_pipeline_config()  # FUNCTION CALL HERE
       references = config.get('references', {})
   ```

3. `viewer/utils/pipeline_utils.py:get_chemistry()`
   ```python
   def get_chemistry(library_prep_method):
       config = load_pipeline_config()  # FUNCTION CALL HERE
       chemistries = config.get('chemistries', {})
   ```

**Frontend Integration:**
- `viewer/static/viewer/js/pipeline-submit-modal.js` accesses this data via API call
  ```javascript
  fetch('/api/pipeline/config')
    .then(response => response.json())
    .then(config => {
      this.references = config.references;
      this.chemistries = config.chemistries;
    });
  ```

### Utility Functions

#### `is_ingest_complete(fastq_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       # Skip if ingest is not complete
       if not is_ingest_complete(fastq_name):  # FUNCTION CALL HERE
           return {
               'status': 'error',
               'message': f'Ingest is not complete for {fastq_name}'
           }
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       for sample_name in sample_names:
           # Check if ingest is complete
           if not is_ingest_complete(sample_name) and not force_submit:  # FUNCTION CALL HERE
               skipped.append({'fastq_name': sample_name, 'reason': 'Ingest not complete'})
               continue
   ```

**UI Integration:**
- Indirectly used via API call to `/api/pipeline/submit-samples/` from:
  - `viewer/static/viewer/js/pipeline-final-modal.js:executeSubmission()`

#### `determine_workflow(batch_name_from_vendor)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       workflow = determine_workflow(batch_name_from_vendor)  # FUNCTION CALL HERE
       if not workflow:
           workflow = 'rtx'  # Default to RTX
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       # Determine workflow
       workflow = determine_workflow(metadata.batch_name_from_vendor)  # FUNCTION CALL HERE
       if not workflow:
           workflow = 'rtx'  # Default to RTX
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:determineWorkflow()`
  ```javascript
  determineWorkflow(sample, options = {}) {
    const batchName = sample.batch || '';
    if (batchName.includes('MTX') || batchName.startsWith('MTX')) {
      return 'mtx';
    }
    return 'rtx';
  }
  ```

#### `get_reference_name(organism_common_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:create_mtx_alignment_command()`
   ```python
   def create_mtx_alignment_command(sample):
       reference_name = get_reference_name(sample['organism_common_name'])  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:create_rtx_alignment_command()`
   ```python
   def create_rtx_alignment_command(sample):
       reference_name = get_reference_name(sample['organism_common_name'])  # FUNCTION CALL HERE
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:getReference()`
  ```javascript
  getReference(organism) {
    // Access config from API response
    const references = this.references || {};
    return references[organism] || 'Unknown';
  }
  ```

#### `get_chemistry(library_prep_method)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:create_rtx_alignment_command()`
   ```python
   def create_rtx_alignment_command(sample):
       chemistry = get_chemistry(sample['library_prep'])  # FUNCTION CALL HERE
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:getChemistry()`
  ```javascript
  getChemistry(libraryPrep) {
    // Access config from API response
    const chemistries = this.chemistries || {};
    return chemistries[libraryPrep] || 'Unknown';
  }
  ```

### Script Execution Functions

#### `create_bash_script(commands, script_name='temp_script.sh')`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       script_path = create_bash_script([command], f"submit_{fastq_name}.sh")  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:check_job_status()`
   ```python
   def check_job_status(demand_id):
       script_path = create_bash_script([command], f"check_status_{demand_id}.sh")  # FUNCTION CALL HERE
   ```

3. `viewer/utils/pipeline_utils.py:stop_job()`
   ```python
   def stop_job(demand_id):
       script_path = create_bash_script([command], f"stop_job_{demand_id}.sh")  # FUNCTION CALL HERE
   ```

4. `viewer/utils/pipeline_utils.py:count_running_jobs()`
   ```python
   def count_running_jobs():
       script_path = create_bash_script([command], "count_running_jobs.sh")  # FUNCTION CALL HERE
   ```

5. `viewer/utils/pipeline_utils.py:get_ocs_running_jobs()`
   ```python
   def get_ocs_running_jobs():
       script_path = create_bash_script([command], "get_ocs_running_jobs.sh")  # FUNCTION CALL HERE
   ```

#### `run_bash_script(script_path)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       script_path = create_bash_script([command], f"submit_{fastq_name}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:check_job_status()`
   ```python
   def check_job_status(demand_id):
       script_path = create_bash_script([command], f"check_status_{demand_id}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

3. `viewer/utils/pipeline_utils.py:stop_job()`
   ```python
   def stop_job(demand_id):
       script_path = create_bash_script([command], f"stop_job_{demand_id}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

4. `viewer/utils/pipeline_utils.py:count_running_jobs()`
   ```python
   def count_running_jobs():
       script_path = create_bash_script([command], "count_running_jobs.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

5. `viewer/utils/pipeline_utils.py:get_ocs_running_jobs()`
   ```python
   def get_ocs_running_jobs():
       script_path = create_bash_script([command], "get_ocs_running_jobs.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

### Command Generation Functions

#### `create_mtx_alignment_command(sample)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       if workflow == 'mtx':
           command = create_mtx_alignment_command(sample)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       if workflow == 'mtx':
           command = create_mtx_alignment_command({  # FUNCTION CALL HERE
               'organism_common_name': metadata.organism_common_name,
               'load_name': metadata.load_name
           })
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:generateAlignmentCommand()`
  ```javascript
  generateAlignmentCommand(sample) {
    if (this.determineWorkflow(sample) === 'mtx') {
      // MTX command generation logic similar to backend
    }
  }
  ```

#### `create_rtx_alignment_command(sample)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       if workflow == 'rtx':
           command = create_rtx_alignment_command(sample)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       if workflow == 'rtx':
           command = create_rtx_alignment_command({  # FUNCTION CALL HERE
               'organism_common_name': metadata.organism_common_name,
               'load_name': metadata.load_name,
               'library_prep': metadata.library_prep
           })
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:generateAlignmentCommand()`
  ```javascript
  generateAlignmentCommand(sample) {
    if (this.determineWorkflow(sample) === 'rtx') {
      // RTX command generation logic similar to backend
    }
  }
  ```

### Job Submission Functions

#### `submit_sample_from_dashboard(sample)`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       result = submit_sample_from_dashboard({  # FUNCTION CALL HERE
           'fastq_name': sample_name,
           'load_name': metadata.load_name,
           'organism_common_name': metadata.organism_common_name,
           'batch_name_from_vendor': metadata.batch_name_from_vendor,
           'library_prep': metadata.library_prep
       })
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView.retry_failed_job()`
   ```python
   def retry_failed_job(request):
       result = submit_sample_from_dashboard(sample_data)  # FUNCTION CALL HERE
   ```

3. `viewer/core/views.py:process_queue()`
   ```python
   def process_queue(request):
       result = submit_sample_from_dashboard(sample_data)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/pipeline-final-modal.js:executeSubmission()`
  - Triggers API call to `/api/queue/import/`
  - Which leads to `/api/queue/process/` being called
  - Which calls `submit_sample_from_dashboard()`

- `viewer/static/viewer/js/job-monitor.js` (for retry functionality)
  - Calls API endpoint `/api/pipeline/retry-failed-job/`
  - Which calls `PipelineApiView.retry_failed_job()`
  - Which calls `submit_sample_from_dashboard()`

### Job Status Functions

#### `count_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._get_job_data()`
   ```python
   def _get_job_data(self):
       job_counts = cache.get(counts_cache_key)
       if job_counts is None:
           job_counts = count_running_jobs()  # FUNCTION CALL HERE
           cache.set(counts_cache_key, job_counts, timeout=JOB_DATA_CACHE_TIMEOUT)
   ```

2. `viewer/features/pipeline/pipeline.py:JobMonitorView._get_fresh_job_data()`
   ```python
   def _get_fresh_job_data(self):
       job_counts = count_running_jobs()  # FUNCTION CALL HERE
   ```

3. `viewer/core/views.py:process_queue()`
   ```python
   def process_queue(request):
       job_counts = count_running_jobs()  # FUNCTION CALL HERE
       if job_counts['total'] >= max_concurrent_jobs:
           return JsonResponse({'status': 'error', 'message': 'Too many running jobs'})
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:refreshJobs()`
  ```javascript
  refreshJobs(showSuccessToast = false) {
    fetch('/api/pipeline/get-job-data/')  // Calls endpoint that uses count_running_jobs()
      .then(response => response.json())
      .then(data => {
        this.updateJobCounts(data.job_counts);
      });
  }
  ```

#### `check_job_status(demand_id)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       status_result = check_job_status(demand_id)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView._check_by_demand_id()`
   ```python
   def _check_by_demand_id(demand_id):
       result = check_job_status(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:checkJobStatus()`
  ```javascript
  checkJobStatus(demandId) {
    fetch(`/api/pipeline/check-job-status/${demandId}/`, {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

#### `stop_job(demand_id)`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()`
   ```python
   def stop_alignment(request, demand_id=None):
       result = stop_job(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:stopJob()`
  ```javascript
  stopJob(demandId) {
    fetch(`/api/pipeline/stop-alignment/${demandId}/`, {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ fastq_name: fastqName })
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

### Job Management Functions

#### `move_job_to_destination_table(fastq_name, demand_id, status, demand_type, start_time=None, end_time=None)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       # For completed jobs
       if job_status in ['COMPLETED', 'FAILED', 'ABORTED']:
           move_job_to_destination_table(  # FUNCTION CALL HERE
               fastq_name,
               demand_id,
               job_status,
               demand_type,
               start_time,
               end_time or timezone.now()
           )
   ```

#### `process_auto_proceed_jobs(fastq_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       # For completed alignment jobs, check for auto-proceed
       if job_status == 'COMPLETED' and demand_type == 'align':
           process_auto_proceed_jobs(fastq_name)  # FUNCTION CALL HERE
   ```

**Triggered By:**
- Auto-proceed workflow when alignment job completes:
  1. Queue processing picks up alignment job
  2. Job completes
  3. Status update is triggered
  4. `process_job_status_update()` calls `process_auto_proceed_jobs()`
  5. Post-QC job is updated in queue from "PENDING" to "Ready"

#### `process_job_status_update(demand_id)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:update_all_running_jobs()`
   ```python
   def update_all_running_jobs():
       for running_job in running_jobs:
           process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView.check_job_status()`
   ```python
   def check_job_status(request, demand_id):
       result = process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

3. `viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()`
   ```python
   def stop_alignment(request, demand_id=None):
       update_result = process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:checkJobStatus()`
  - Makes API call to `/api/pipeline/check-job-status/`
  - Which calls `process_job_status_update()`

- `viewer/static/viewer/js/job-monitor.js:stopJob()`
  - Makes API call to `/api/pipeline/stop-alignment/`
  - Which calls `stop_job()`, then `process_job_status_update()`

### Job Polling and Queue Functions

#### `update_all_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._update_jobs_async()`
   ```python
   def _update_jobs_async(self, user_id):
       results = update_all_running_jobs()  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:JobMonitorView._update_jobs_async()`
   ```python
   def _update_jobs_async(self, user_id):
       update_all_running_jobs()  # FUNCTION CALL HERE
   ```

3. `viewer/features/pipeline/pipeline.py:PipelineApiView.update_all_jobs()`
   ```python
   def update_all_jobs(request):
       updated_jobs = update_all_running_jobs()  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:refreshAllJobStatuses()`
  ```javascript
  refreshAllJobStatuses() {
    fetch('/api/pipeline/update_all_jobs/', {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

#### `get_ocs_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineApiView.get_queue_data()`
   ```python
   def get_queue_data(request):
       queue_data = get_ocs_running_jobs()  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/queue-management.js:fetchQueueData()`
  ```javascript
  fetchQueueData() {
    fetch('/api/pipeline/get-queue-data/')
      .then(response => response.json())
      .then(data => {
        this.updateQueueDisplay(data);
      });
  }
  ```

## Call Stack Diagrams

This section provides detailed call stack diagrams for key workflows in the pipeline system, showing the exact sequence of function calls from UI events through the backend pipeline.

### Job Submission Call Stack

When a user submits samples for processing via the Pipeline Dashboard:

```
1. UI Event: Click "Submit" button in dashboard.html
   ↓
2. pipeline-dashboard.js:handleSubmitAction()
   ↓
3. pipeline-submit-modal.js:openModal()
   ↓
4. User configures options and clicks "Next"
   ↓
5. pipeline-submit-modal.js:handleSubmission()
   ↓
6. pipeline-final-modal.js:show()
   ↓
7. User clicks "Execute"
   ↓
8. pipeline-final-modal.js:executeSubmission()
   ↓
9. fetch('/api/queue/import/')
   ↓
10. core/views.py:import_queue()
    ↓
11. Add jobs to queue_jobs table
    ↓
12. queue-management.js:processQueue()
    ↓
13. fetch('/api/queue/process/')
    ↓
14. core/views.py:process_queue()
    ↓
15. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
    ↓
16. viewer/utils/pipeline_utils.py:determine_workflow()
    ↓
17. If MTX: viewer/utils/pipeline_utils.py:create_mtx_alignment_command()
    If RTX: viewer/utils/pipeline_utils.py:create_rtx_alignment_command()
    ↓
18. viewer/utils/pipeline_utils.py:create_bash_script()
    ↓
19. viewer/utils/pipeline_utils.py:run_bash_script()
    ↓
20. OCS CLI submits job
    ↓
21. Job ID returned and saved to database
```

### Job Status Checking Call Stack

When a user checks the status of a specific job:

```
1. UI Event: Click "Check Status" button in job_monitor.html
   ↓
2. job-monitor.js:checkJobStatus(demandId)
   ↓
3. fetch('/api/pipeline/check-job-status/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.check_job_status()
   ↓
5. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
6. viewer/utils/pipeline_utils.py:check_job_status()
   ↓
7. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
8. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
9. Parse OCS CLI output
   ↓
10. If job complete/failed:
    viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. If alignment completed successfully:
    viewer/utils/pipeline_utils.py:process_auto_proceed_jobs()
    ↓
12. Database updated (running_jobs, completed_jobs, failed_jobs tables)
    ↓
13. Status returned to frontend
    ↓
14. job-monitor.js updates UI
```

### Auto-Refresh Job Status Call Stack

The background job status update process:

```
1. Timer Event: job-monitor.js:autoRefreshInterval triggers
   ↓
2. job-monitor.js:refreshJobs()
   ↓
3. fetch('/api/pipeline/get-job-data/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.get_job_data()
   ↓
5. viewer/features/pipeline/pipeline.py:JobMonitorView._get_fresh_job_data()
   ↓
6. viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
7. Periodically (less frequently):
   job-monitor.js:refreshAllJobStatuses()
   ↓
8. fetch('/api/pipeline/update_all_jobs/')
   ↓
9. viewer/features/pipeline/pipeline.py:PipelineApiView.update_all_jobs()
   ↓
10. viewer/utils/pipeline_utils.py:update_all_running_jobs()
    ↓
11. For each running job:
    viewer/utils/pipeline_utils.py:process_job_status_update()
    ↓
12. Database updated
    ↓
13. Fresh data returned to frontend
    ↓
14. job-monitor.js updates UI tables and counts
```

### Stop Job Call Stack

When a user stops a running job:

```
1. UI Event: Click "Stop" button in job_monitor.html
   ↓
2. job-monitor.js:stopJob(demandId)
   ↓
3. fetch('/api/pipeline/stop-alignment/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()
   ↓
5. viewer/utils/pipeline_utils.py:stop_job()
   ↓
6. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
7. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
8. OCS CLI stops job
   ↓
9. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
10. viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. Database updated (running_jobs → completed_jobs with status="ABORTED")
    ↓
12. Status returned to frontend
    ↓
13. job-monitor.js updates UI
```

### Auto-Proceed Workflow Call Stack

The complete auto-proceed workflow from alignment to post-QC:

```
1. UI Event: Enable Auto-Proceed toggle in submission modal
   ↓
2. pipeline-submit-modal.js:handleAutoProceedToggle()
   ↓
3. pipeline-final-modal.js:executeSubmission()
   ↓
4. fetch('/api/queue/import/')
   ↓
5. core/views.py:import_queue()
   ↓
6. Create two queue entries in queue_jobs table:
   - Alignment with status="Ready"
   - PostQC with status="PENDING"
   ↓
7. queue-management.js:processQueue()
   ↓
8. fetch('/api/queue/process/')
   ↓
9. core/views.py:process_queue()
   ↓
10. Submit alignment job via submit_sample_from_dashboard()
    ↓
11. Alignment job runs in OCS
    ↓
12. job-monitor.js timer triggers status update
    ↓
13. update_all_running_jobs()
    ↓
14. process_job_status_update() detects completed alignment
    ↓
15. process_auto_proceed_jobs(fastq_name)
    ↓
16. Find PENDING PostQC job for same FASTQ
    ↓
17. Update status from "PENDING" → "Ready"
    ↓
18. Next queue processing cycle:
    core/views.py:process_queue()
    ↓
19. Submit PostQC job via submit_sample_from_dashboard()
    ↓
20. PostQC job runs in OCS
    ↓
21. Process completes
```

### Failed Job Retry Call Stack

When a user retries a failed job:

```
1. UI Event: Click "Retry" button in failed_jobs.html
   ↓
2. Form submission to /api/pipeline/retry-failed-job/
   ↓
3. viewer/features/pipeline/pipeline.py:PipelineApiView.retry_failed_job()
   ↓
4. Get sample metadata from database
   ↓
5. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
6. Generate command and submit to OCS
   ↓
7. Update database:
   - Increment retry_count in Alignment/PostQC table
   - Update status to "SUBMITTED"
   - Remove record from failed_jobs table
   - Add to queue_jobs if necessary
   ↓
8. Return status to frontend
   ↓
9. Redirect to job_monitor.html
```

### Queue Management Call Stack

The queue processing workflow:

```
1. Timer Event: queue-management.js auto-processing timer triggers
   ↓
2. queue-management.js:processQueue()
   ↓
3. fetch('/api/queue/process/')
   ↓
4. core/views.py:process_queue()
   ↓
5. Check if max concurrent jobs reached:
   viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
6. Get next "Ready" job from queue_jobs table
   ↓
7. For each ready job:
   viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
8. On successful submission:
   - Remove from queue_jobs
   - Add to running_jobs
   - Update Alignment/PostQC table
   ↓
9. Return status to frontend
   ↓
10. queue-management.js updates UI
```

## UI Element to Backend Function Mapping

This section maps specific UI elements in the HTML templates to their JavaScript handlers and the corresponding backend functions they ultimately trigger. This direct tracing helps understand exactly how user interactions flow through the system.

### Dashboard Page (dashboard.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Submit Button | `submit-action-btn` | click | `pipeline-dashboard.js:handleSubmitAction()` | - | - |
| Sample Row Checkbox | `sample-checkbox-{id}` | change | `pipeline-dashboard.js:handleSampleSelection()` | - | - |
| Submit Selected | `submit-selected-btn` | click | `pipeline-dashboard.js:handleSubmitSelected()` | - | - |

### Submission Modal (pipeline-submit-modal.js)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Auto-Proceed Toggle | `auto-proceed-toggle` | change | `pipeline-submit-modal.js:handleAutoProceedToggle()` | - | - |
| Chemistry Dropdown | `chemistry-dropdown` | change | `pipeline-submit-modal.js:handleChemistryChange()` | - | `get_chemistry()` (equivalent) |
| Reference Dropdown | `reference-dropdown` | change | `pipeline-submit-modal.js:handleReferenceChange()` | - | `get_reference_name()` (equivalent) |
| Next Button | `submit-next-btn` | click | `pipeline-submit-modal.js:handleSubmission()` | - | - |

### Final Review Modal (pipeline-final-modal.js)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Execute Button | `execute-btn` | click | `pipeline-final-modal.js:executeSubmission()` | `/api/queue/import/` | `core/views.py:import_queue()` |
| Cancel Button | `cancel-btn` | click | `pipeline-final-modal.js:hide()` | - | - |
| Edit Commands Toggle | `edit-commands-toggle` | change | `pipeline-final-modal.js:toggleEditCommands()` | - | - |

### Job Monitor Page (job_monitor.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Refresh Button | `refreshNowBtn` | click | `job-monitor.js:refreshJobs()` | `/api/pipeline/get-job-data/` | `PipelineApiView.get_job_data()` → `count_running_jobs()` |
| Auto-Refresh Toggle | `autoRefreshToggle` | change | `job-monitor.js:toggleAutoRefresh()` | - | - |
| Update All Button | `updateAllBtn` | click | `job-monitor.js:refreshAllJobStatuses()` | `/api/pipeline/update_all_jobs/` | `PipelineApiView.update_all_jobs()` → `update_all_running_jobs()` |
| Check Status Button | `check-status-btn-{job_id}` | click | `job-monitor.js:checkJobStatus()` | `/api/pipeline/check-job-status/{id}/` | `PipelineApiView.check_job_status()` → `process_job_status_update()` → `check_job_status()` |
| Stop Job Button | `stop-job-btn-{job_id}` | click | `job-monitor.js:stopJob()` | `/api/pipeline/stop-alignment/{id}/` | `PipelineApiView.stop_alignment()` → `stop_job()` |

### Queue Management Page (queue_management.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Process Queue Button | `process-queue-btn` | click | `queue-management.js:processQueue()` | `/api/queue/process/` | `core/views.py:process_queue()` → `submit_sample_from_dashboard()` |
| Pause Queue Button | `pause-queue-btn` | click | `queue-management.js:toggleQueuePause()` | - | - |
| Refresh Queue Button | `refresh-queue-btn` | click | `queue-management.js:fetchQueueData()` | `/api/queue/get_data/` | `core/views.py:get_queue_data()` |
| Auto-Process Toggle | `auto-process-toggle` | change | `queue-management.js:toggleAutoProcessing()` | - | - |
| Remove Queue Item | `remove-queue-item-{id}` | click | `queue-management.js:removeQueueItem()` | `/api/queue/remove/{id}/` | `core/views.py:remove_queue_item()` |

### Failed Jobs Page (failed_jobs.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Retry Job Button | `retry-failed-job-{id}` | click | Form submission | `/api/pipeline/retry-failed-job/` | `PipelineApiView.retry_failed_job()` → `submit_sample_from_dashboard()` |
| Cancel Job Button | `cancel-failed-job-{id}` | click | Form submission | `/api/pipeline/cancel-failed-job/` | `PipelineApiView.cancel_failed_job()` |
| Job Type Filter | `job-type-filter` | change | `failed-jobs.js:filterJobs()` | - | - |
| Status Filter | `status-filter` | change | `failed-jobs.js:filterJobs()` | - | - |

### OCS Browser Page (ocs-browser.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Import Selected Button | `import-selected-btn` | click | `ocs-browser.js:importSelected()` | - | - |
| Sample Checkbox | `sample-checkbox-{id}` | change | `ocs-browser.js:handleSampleSelection()` | - | - |
| Save Selected Button | `save-selected-btn` | click | `ocs-browser.js:saveSelectedToPipeline()` | - | Stores in `pipeline-local-data.js` |

### DOM Element Detailed Tracing Examples

#### Job Status Checking Flow

When a user clicks the "Check Status" button for a job in the job monitor:

```
1. User clicks <button id="check-status-btn-12345" data-demand-id="demand-12345">Check Status</button>
   ↓
2. Event triggers job-monitor.js:checkJobStatus(demandId)
   ↓
3. JavaScript extracts demand_id from data-attribute
   ↓
4. fetch('/api/pipeline/check-job-status/demand-12345/', { method: 'POST' })
   ↓
5. Django routes to PipelineApiView.check_job_status(request, demand_id="demand-12345")
   ↓
6. process_job_status_update(demand_id="demand-12345")
   ↓
7. check_job_status(demand_id="demand-12345")
   ↓
8. OCS status check and database update
   ↓
9. Response to frontend
   ↓
10. job-monitor.js updates DOM: 
    - Status badge color changes
    - Toast notification appears
    - Row may disappear (if job completed)
```

#### Sample Submission Flow

When a user submits samples from the dashboard:

```
1. User selects samples with <input type="checkbox" class="sample-checkbox" id="sample-checkbox-123">
   ↓
2. User clicks <button id="submit-selected-btn">Submit Selected</button>
   ↓
3. Event triggers pipeline-dashboard.js:handleSubmitSelected()
   ↓
4. JavaScript retrieves selected sample IDs from checkboxes
   ↓
5. pipeline-submit-modal.js:openModal() displays modal with <div id="submission-modal">
   ↓
6. User configures options and toggles:
   - <select id="reference-dropdown">
   - <select id="chemistry-dropdown">
   - <input type="checkbox" id="auto-proceed-toggle">
   ↓
7. User clicks <button id="submit-next-btn">Next</button>
   ↓
8. Event triggers pipeline-submit-modal.js:handleSubmission()
   ↓
9. pipeline-final-modal.js:show() displays final review modal
   ↓
10. User clicks <button id="execute-btn">Execute</button>
    ↓
11. Event triggers pipeline-final-modal.js:executeSubmission()
    ↓
12. fetch('/api/queue/import/', { method: 'POST', body: JSON.stringify(commands) })
    ↓
13. Django routes to core/views.py:import_queue()
    ↓
14. Database updates (queue_jobs table)
    ↓
15. Success message displayed in UI
```

#### Auto-Proceed Toggle Effect

The auto-proceed toggle has a specific flow that affects how jobs progress:

```
1. User toggles <input type="checkbox" id="auto-proceed-toggle">
   ↓
2. Event triggers pipeline-submit-modal.js:handleAutoProceedToggle()
   ↓
3. JavaScript stores setting in local state
   ↓
4. When final submission happens with pipeline-final-modal.js:executeSubmission()
   ↓
5. If auto-proceed is enabled:
   - Alignment command marked with status="Ready"
   - PostQC command marked with status="PENDING"
   ↓
6. Both sent to backend in fetch('/api/queue/import/')
   ↓
7. core/views.py:import_queue() creates two entries in queue_jobs
   ↓
8. Only the "Ready" alignment job is processed initially
   ↓
9. When alignment completes:
   process_job_status_update() → process_auto_proceed_jobs()
   ↓
10. process_auto_proceed_jobs() updates PostQC status from "PENDING" to "Ready"
    ↓
11. Next queue processing cycle picks up the now-Ready PostQC job
```

#### Job Status Monitoring Loop

```
JobMonitorView.__init__() creates page context
↓
job-monitor.js initializes with autoRefreshInterval
↓                                             ↑
job-monitor.js:refreshJobs()                  |
↓                                             |
fetch('/api/pipeline/get-job-data/')          |
↓                                             |
PipelineApiView.get_job_data()                |
↓                                             |
count_running_jobs() and database queries     |
↓                                             |
Return data to frontend                       |
↓                                             |
job-monitor.js updates UI tables and badges   |
↓                                             |
Wait for next interval ----------------------→|
```

### Frontend Component Details

#### job-monitor.js

This JavaScript file is responsible for the job monitoring interface. Key features:

1. **Automatic Refresh**: Sets up intervals to refresh job data automatically
   ```javascript
   // job-monitor.js
   startAutoRefresh() {
     this.autoRefreshInterval = setInterval(() => {
       this.refreshJobs(false);
     }, this.autoRefreshTime);
   }
   ```

2. **Manual Refresh**: Handles user-triggered refresh of job data
   ```javascript
   // job-monitor.js
   refreshJobs(showSuccessToast = false) {
     // Uses fetch() to call /api/pipeline/get-job-data/
     // This triggers count_running_jobs() on the backend
   }
   ```

3. **Status Checking**: Provides UI for checking individual job status
   ```javascript
   // job-monitor.js
   checkJobStatus(demandId) {
     // Uses fetch() to call /api/pipeline/check-job-status/{demandId}/
     // This triggers check_job_status() on the backend
   }
   ```

4. **Job Stopping**: Allows users to stop running jobs
   ```javascript
   // job-monitor.js
   stopJob(demandId) {
     // Uses fetch() to call /api/pipeline/stop-alignment/{demandId}/
     // This triggers stop_job() on the backend
   }
   ```

#### queue-management.js

This JavaScript file handles the queue management interface. Key features:

1. **Queue Fetching**: Retrieves queue data from the server
   ```javascript
   // queue-management.js
   fetchQueueData() {
     // Uses fetch() to call /api/queue/get_data/
     // Displays queue items with pagination
   }
   ```

2. **Auto Processing**: Sets up automatic processing of queued jobs
   ```javascript
   // queue-management.js
   startAutoProcessing() {
     // Sets up timer to call processQueue() automatically
   }
   
   processQueue() {
     // Uses fetch() to call /api/queue/process/
     // This triggers submit_sample_from_dashboard() for Ready jobs
   }
   ```

3. **Queue Control**: Provides UI for pausing/resuming queue processing
   ```javascript
   // queue-management.js
   toggleQueuePause() {
     // Pauses or resumes automatic queue processing
   }
   ```

#### pipeline-submit-modal.js

This JavaScript file handles the submission modal interface. Key features:

1. **Command Generation**: Creates commands based on selected options
   ```javascript
   // pipeline-submit-modal.js
   generateAlignmentCommand(sample) {
     // Frontend equivalent of create_mtx_alignment_command/create_rtx_alignment_command
   }
   ```

2. **Workflow Determination**: Identifies workflow type based on sample data
   ```javascript
   // pipeline-submit-modal.js
   determineWorkflow(sample, options = {}) {
     // Frontend equivalent of determine_workflow()
   }
   ```

3. **Reference/Chemistry Selection**: Provides dropdowns for reference and chemistry
   ```javascript
   // pipeline-submit-modal.js
   getReference(organism) {
     // Frontend equivalent of get_reference_name()
   }
   
   getChemistry(libraryPrep) {
     // Frontend equivalent of get_chemistry()
   }
   ```

#### pipeline-final-modal.js

This JavaScript file handles the final review and execution interface. Key features:

1. **Command Display**: Shows final commands for user review
   ```javascript
   // pipeline-final-modal.js
   show(data) {
     // Displays alignment and post-QC commands for review
   }
   ```

2. **Job Submission**: Submits commands to the queue for processing
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // Uses fetch() to call /api/queue/import/
     // Creates entries in queue_jobs table
   }
   ```

3. **Auto-Proceed Setup**: Handles setting up auto-proceed workflow
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // If auto-proceed enabled, marks PostQC jobs with PENDING status
   }
   ```

### HTML View Templates

#### dashboard.html

The dashboard template displays the main pipeline dashboard with:
- Sample selection table
- Submit button that triggers the submission modal
- Job statistics powered by `count_running_jobs()`

#### job_monitor.html

The job monitor template displays:
- Running jobs table
- Completed jobs table
- Job status counts
- Auto-refresh toggle
- Refresh button
- Check status and stop buttons for individual jobs

#### queue_management.html

The queue management template displays:
- Queue items table
- Process queue button
- Pause/resume queue button
- Auto-processing settings
- Queue statistics

#### failed_jobs.html

The failed jobs template displays:
- Failed jobs table with retry and cancel options
- Failure details
- Retry buttons that trigger `PipelineApiView.retry_failed_job()`

### Database Tables and Models Integration

The following database models are essential to the pipeline system:

1. **RunningJob**: Stores currently running jobs
   - Used by `process_job_status_update()` to track job status
   - Updated by `move_job_to_destination_table()`

2. **CompletedJob**: Stores successfully completed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in job_monitor.html

3. **FailedJob**: Stores failed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in failed_jobs.html

4. **QueueJobs**: Stores jobs waiting to be processed
   - Created by `pipeline-final-modal.js:executeSubmission()`
   - Processed by `process_queue()`
   - Updated by `process_auto_proceed_jobs()`

## Function-Level Call Tracing

This section provides detailed tracing of how each function in `pipeline_utils.py` is used across the application, documenting the exact file paths and call stacks.

### Configuration Functions

#### `load_pipeline_config()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._get_pipeline_config()`
   ```python
   def _get_pipeline_config(self):
       config_cache_key = 'pipeline_config'
       config = cache.get(config_cache_key)
       if config is None:
           config = load_pipeline_config()  # FUNCTION CALL HERE
           cache.set(config_cache_key, config, timeout=PIPELINE_CONFIG_CACHE_TIMEOUT)
   ```

2. `viewer/utils/pipeline_utils.py:get_reference_name()`
   ```python
   def get_reference_name(organism_common_name):
       config = load_pipeline_config()  # FUNCTION CALL HERE
       references = config.get('references', {})
   ```

3. `viewer/utils/pipeline_utils.py:get_chemistry()`
   ```python
   def get_chemistry(library_prep_method):
       config = load_pipeline_config()  # FUNCTION CALL HERE
       chemistries = config.get('chemistries', {})
   ```

**Frontend Integration:**
- `viewer/static/viewer/js/pipeline-submit-modal.js` accesses this data via API call
  ```javascript
  fetch('/api/pipeline/config')
    .then(response => response.json())
    .then(config => {
      this.references = config.references;
      this.chemistries = config.chemistries;
    });
  ```

### Utility Functions

#### `is_ingest_complete(fastq_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       # Skip if ingest is not complete
       if not is_ingest_complete(fastq_name):  # FUNCTION CALL HERE
           return {
               'status': 'error',
               'message': f'Ingest is not complete for {fastq_name}'
           }
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       for sample_name in sample_names:
           # Check if ingest is complete
           if not is_ingest_complete(sample_name) and not force_submit:  # FUNCTION CALL HERE
               skipped.append({'fastq_name': sample_name, 'reason': 'Ingest not complete'})
               continue
   ```

**UI Integration:**
- Indirectly used via API call to `/api/pipeline/submit-samples/` from:
  - `viewer/static/viewer/js/pipeline-final-modal.js:executeSubmission()`

#### `determine_workflow(batch_name_from_vendor)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       workflow = determine_workflow(batch_name_from_vendor)  # FUNCTION CALL HERE
       if not workflow:
           workflow = 'rtx'  # Default to RTX
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       # Determine workflow
       workflow = determine_workflow(metadata.batch_name_from_vendor)  # FUNCTION CALL HERE
       if not workflow:
           workflow = 'rtx'  # Default to RTX
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:determineWorkflow()`
  ```javascript
  determineWorkflow(sample, options = {}) {
    const batchName = sample.batch || '';
    if (batchName.includes('MTX') || batchName.startsWith('MTX')) {
      return 'mtx';
    }
    return 'rtx';
  }
  ```

#### `get_reference_name(organism_common_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:create_mtx_alignment_command()`
   ```python
   def create_mtx_alignment_command(sample):
       reference_name = get_reference_name(sample['organism_common_name'])  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:create_rtx_alignment_command()`
   ```python
   def create_rtx_alignment_command(sample):
       reference_name = get_reference_name(sample['organism_common_name'])  # FUNCTION CALL HERE
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:getReference()`
  ```javascript
  getReference(organism) {
    // Access config from API response
    const references = this.references || {};
    return references[organism] || 'Unknown';
  }
  ```

#### `get_chemistry(library_prep_method)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:create_rtx_alignment_command()`
   ```python
   def create_rtx_alignment_command(sample):
       chemistry = get_chemistry(sample['library_prep'])  # FUNCTION CALL HERE
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:getChemistry()`
  ```javascript
  getChemistry(libraryPrep) {
    // Access config from API response
    const chemistries = this.chemistries || {};
    return chemistries[libraryPrep] || 'Unknown';
  }
  ```

### Script Execution Functions

#### `create_bash_script(commands, script_name='temp_script.sh')`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       script_path = create_bash_script([command], f"submit_{fastq_name}.sh")  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:check_job_status()`
   ```python
   def check_job_status(demand_id):
       script_path = create_bash_script([command], f"check_status_{demand_id}.sh")  # FUNCTION CALL HERE
   ```

3. `viewer/utils/pipeline_utils.py:stop_job()`
   ```python
   def stop_job(demand_id):
       script_path = create_bash_script([command], f"stop_job_{demand_id}.sh")  # FUNCTION CALL HERE
   ```

4. `viewer/utils/pipeline_utils.py:count_running_jobs()`
   ```python
   def count_running_jobs():
       script_path = create_bash_script([command], "count_running_jobs.sh")  # FUNCTION CALL HERE
   ```

5. `viewer/utils/pipeline_utils.py:get_ocs_running_jobs()`
   ```python
   def get_ocs_running_jobs():
       script_path = create_bash_script([command], "get_ocs_running_jobs.sh")  # FUNCTION CALL HERE
   ```

#### `run_bash_script(script_path)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       script_path = create_bash_script([command], f"submit_{fastq_name}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

2. `viewer/utils/pipeline_utils.py:check_job_status()`
   ```python
   def check_job_status(demand_id):
       script_path = create_bash_script([command], f"check_status_{demand_id}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

3. `viewer/utils/pipeline_utils.py:stop_job()`
   ```python
   def stop_job(demand_id):
       script_path = create_bash_script([command], f"stop_job_{demand_id}.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

4. `viewer/utils/pipeline_utils.py:count_running_jobs()`
   ```python
   def count_running_jobs():
       script_path = create_bash_script([command], "count_running_jobs.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

5. `viewer/utils/pipeline_utils.py:get_ocs_running_jobs()`
   ```python
   def get_ocs_running_jobs():
       script_path = create_bash_script([command], "get_ocs_running_jobs.sh")
       result = run_bash_script(script_path)  # FUNCTION CALL HERE
   ```

### Command Generation Functions

#### `create_mtx_alignment_command(sample)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       if workflow == 'mtx':
           command = create_mtx_alignment_command(sample)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       if workflow == 'mtx':
           command = create_mtx_alignment_command({  # FUNCTION CALL HERE
               'organism_common_name': metadata.organism_common_name,
               'load_name': metadata.load_name
           })
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:generateAlignmentCommand()`
  ```javascript
  generateAlignmentCommand(sample) {
    if (this.determineWorkflow(sample) === 'mtx') {
      // MTX command generation logic similar to backend
    }
  }
  ```

#### `create_rtx_alignment_command(sample)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()`
   ```python
   def submit_sample_from_dashboard(sample):
       if workflow == 'rtx':
           command = create_rtx_alignment_command(sample)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       if workflow == 'rtx':
           command = create_rtx_alignment_command({  # FUNCTION CALL HERE
               'organism_common_name': metadata.organism_common_name,
               'load_name': metadata.load_name,
               'library_prep': metadata.library_prep
           })
   ```

**Frontend Equivalent:**
- `viewer/static/viewer/js/pipeline-submit-modal.js:generateAlignmentCommand()`
  ```javascript
  generateAlignmentCommand(sample) {
    if (this.determineWorkflow(sample) === 'rtx') {
      // RTX command generation logic similar to backend
    }
  }
  ```

### Job Submission Functions

#### `submit_sample_from_dashboard(sample)`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:submit_samples()`
   ```python
   def submit_samples(request):
       result = submit_sample_from_dashboard({  # FUNCTION CALL HERE
           'fastq_name': sample_name,
           'load_name': metadata.load_name,
           'organism_common_name': metadata.organism_common_name,
           'batch_name_from_vendor': metadata.batch_name_from_vendor,
           'library_prep': metadata.library_prep
       })
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView.retry_failed_job()`
   ```python
   def retry_failed_job(request):
       result = submit_sample_from_dashboard(sample_data)  # FUNCTION CALL HERE
   ```

3. `viewer/core/views.py:process_queue()`
   ```python
   def process_queue(request):
       result = submit_sample_from_dashboard(sample_data)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/pipeline-final-modal.js:executeSubmission()`
  - Triggers API call to `/api/queue/import/`
  - Which leads to `/api/queue/process/` being called
  - Which calls `submit_sample_from_dashboard()`

- `viewer/static/viewer/js/job-monitor.js` (for retry functionality)
  - Calls API endpoint `/api/pipeline/retry-failed-job/`
  - Which calls `PipelineApiView.retry_failed_job()`
  - Which calls `submit_sample_from_dashboard()`

### Job Status Functions

#### `count_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._get_job_data()`
   ```python
   def _get_job_data(self):
       job_counts = cache.get(counts_cache_key)
       if job_counts is None:
           job_counts = count_running_jobs()  # FUNCTION CALL HERE
           cache.set(counts_cache_key, job_counts, timeout=JOB_DATA_CACHE_TIMEOUT)
   ```

2. `viewer/features/pipeline/pipeline.py:JobMonitorView._get_fresh_job_data()`
   ```python
   def _get_fresh_job_data(self):
       job_counts = count_running_jobs()  # FUNCTION CALL HERE
   ```

3. `viewer/core/views.py:process_queue()`
   ```python
   def process_queue(request):
       job_counts = count_running_jobs()  # FUNCTION CALL HERE
       if job_counts['total'] >= max_concurrent_jobs:
           return JsonResponse({'status': 'error', 'message': 'Too many running jobs'})
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:refreshJobs()`
  ```javascript
  refreshJobs(showSuccessToast = false) {
    fetch('/api/pipeline/get-job-data/')  // Calls endpoint that uses count_running_jobs()
      .then(response => response.json())
      .then(data => {
        this.updateJobCounts(data.job_counts);
      });
  }
  ```

#### `check_job_status(demand_id)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       status_result = check_job_status(demand_id)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView._check_by_demand_id()`
   ```python
   def _check_by_demand_id(demand_id):
       result = check_job_status(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:checkJobStatus()`
  ```javascript
  checkJobStatus(demandId) {
    fetch(`/api/pipeline/check-job-status/${demandId}/`, {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

#### `stop_job(demand_id)`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()`
   ```python
   def stop_alignment(request, demand_id=None):
       result = stop_job(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:stopJob()`
  ```javascript
  stopJob(demandId) {
    fetch(`/api/pipeline/stop-alignment/${demandId}/`, {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ fastq_name: fastqName })
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

### Job Management Functions

#### `move_job_to_destination_table(fastq_name, demand_id, status, demand_type, start_time=None, end_time=None)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       # For completed jobs
       if job_status in ['COMPLETED', 'FAILED', 'ABORTED']:
           move_job_to_destination_table(  # FUNCTION CALL HERE
               fastq_name,
               demand_id,
               job_status,
               demand_type,
               start_time,
               end_time or timezone.now()
           )
   ```

#### `process_auto_proceed_jobs(fastq_name)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:process_job_status_update()`
   ```python
   def process_job_status_update(demand_id):
       # For completed alignment jobs, check for auto-proceed
       if job_status == 'COMPLETED' and demand_type == 'align':
           process_auto_proceed_jobs(fastq_name)  # FUNCTION CALL HERE
   ```

**Triggered By:**
- Auto-proceed workflow when alignment job completes:
  1. Queue processing picks up alignment job
  2. Job completes
  3. Status update is triggered
  4. `process_job_status_update()` calls `process_auto_proceed_jobs()`
  5. Post-QC job is updated in queue from "PENDING" to "Ready"

#### `process_job_status_update(demand_id)`

**Backend Callers:**
1. `viewer/utils/pipeline_utils.py:update_all_running_jobs()`
   ```python
   def update_all_running_jobs():
       for running_job in running_jobs:
           process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:PipelineApiView.check_job_status()`
   ```python
   def check_job_status(request, demand_id):
       result = process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

3. `viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()`
   ```python
   def stop_alignment(request, demand_id=None):
       update_result = process_job_status_update(demand_id)  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:checkJobStatus()`
  - Makes API call to `/api/pipeline/check-job-status/`
  - Which calls `process_job_status_update()`

- `viewer/static/viewer/js/job-monitor.js:stopJob()`
  - Makes API call to `/api/pipeline/stop-alignment/`
  - Which calls `stop_job()`, then `process_job_status_update()`

### Job Polling and Queue Functions

#### `update_all_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineDashboardView._update_jobs_async()`
   ```python
   def _update_jobs_async(self, user_id):
       results = update_all_running_jobs()  # FUNCTION CALL HERE
   ```

2. `viewer/features/pipeline/pipeline.py:JobMonitorView._update_jobs_async()`
   ```python
   def _update_jobs_async(self, user_id):
       update_all_running_jobs()  # FUNCTION CALL HERE
   ```

3. `viewer/features/pipeline/pipeline.py:PipelineApiView.update_all_jobs()`
   ```python
   def update_all_jobs(request):
       updated_jobs = update_all_running_jobs()  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/job-monitor.js:refreshAllJobStatuses()`
  ```javascript
  refreshAllJobStatuses() {
    fetch('/api/pipeline/update_all_jobs/', {
      method: 'POST',
      headers: {
        'X-CSRFToken': this.csrfToken,
        'Content-Type': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update UI based on response
    });
  }
  ```

#### `get_ocs_running_jobs()`

**Backend Callers:**
1. `viewer/features/pipeline/pipeline.py:PipelineApiView.get_queue_data()`
   ```python
   def get_queue_data(request):
       queue_data = get_ocs_running_jobs()  # FUNCTION CALL HERE
   ```

**Frontend Triggered By:**
- `viewer/static/viewer/js/queue-management.js:fetchQueueData()`
  ```javascript
  fetchQueueData() {
    fetch('/api/pipeline/get-queue-data/')
      .then(response => response.json())
      .then(data => {
        this.updateQueueDisplay(data);
      });
  }
  ```

## Call Stack Diagrams

This section provides detailed call stack diagrams for key workflows in the pipeline system, showing the exact sequence of function calls from UI events through the backend pipeline.

### Job Submission Call Stack

When a user submits samples for processing via the Pipeline Dashboard:

```
1. UI Event: Click "Submit" button in dashboard.html
   ↓
2. pipeline-dashboard.js:handleSubmitAction()
   ↓
3. pipeline-submit-modal.js:openModal()
   ↓
4. User configures options and clicks "Next"
   ↓
5. pipeline-submit-modal.js:handleSubmission()
   ↓
6. pipeline-final-modal.js:show()
   ↓
7. User clicks "Execute"
   ↓
8. pipeline-final-modal.js:executeSubmission()
   ↓
9. fetch('/api/queue/import/')
   ↓
10. core/views.py:import_queue()
    ↓
11. Add jobs to queue_jobs table
    ↓
12. queue-management.js:processQueue()
    ↓
13. fetch('/api/queue/process/')
    ↓
14. core/views.py:process_queue()
    ↓
15. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
    ↓
16. viewer/utils/pipeline_utils.py:determine_workflow()
    ↓
17. If MTX: viewer/utils/pipeline_utils.py:create_mtx_alignment_command()
    If RTX: viewer/utils/pipeline_utils.py:create_rtx_alignment_command()
    ↓
18. viewer/utils/pipeline_utils.py:create_bash_script()
    ↓
19. viewer/utils/pipeline_utils.py:run_bash_script()
    ↓
20. OCS CLI submits job
    ↓
21. Job ID returned and saved to database
```

### Job Status Checking Call Stack

When a user checks the status of a specific job:

```
1. UI Event: Click "Check Status" button in job_monitor.html
   ↓
2. job-monitor.js:checkJobStatus(demandId)
   ↓
3. fetch('/api/pipeline/check-job-status/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.check_job_status()
   ↓
5. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
6. viewer/utils/pipeline_utils.py:check_job_status()
   ↓
7. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
8. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
9. Parse OCS CLI output
   ↓
10. If job complete/failed:
    viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. If alignment completed successfully:
    viewer/utils/pipeline_utils.py:process_auto_proceed_jobs()
    ↓
12. Database updated (running_jobs, completed_jobs, failed_jobs tables)
    ↓
13. Status returned to frontend
    ↓
14. job-monitor.js updates UI
```

### Auto-Refresh Job Status Call Stack

The background job status update process:

```
1. Timer Event: job-monitor.js:autoRefreshInterval triggers
   ↓
2. job-monitor.js:refreshJobs()
   ↓
3. fetch('/api/pipeline/get-job-data/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.get_job_data()
   ↓
5. viewer/features/pipeline/pipeline.py:JobMonitorView._get_fresh_job_data()
   ↓
6. viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
7. Periodically (less frequently):
   job-monitor.js:refreshAllJobStatuses()
   ↓
8. fetch('/api/pipeline/update_all_jobs/')
   ↓
9. viewer/features/pipeline/pipeline.py:PipelineApiView.update_all_jobs()
   ↓
10. viewer/utils/pipeline_utils.py:update_all_running_jobs()
    ↓
11. For each running job:
    viewer/utils/pipeline_utils.py:process_job_status_update()
    ↓
12. Database updated
    ↓
13. Fresh data returned to frontend
    ↓
14. job-monitor.js updates UI tables and counts
```

### Stop Job Call Stack

When a user stops a running job:

```
1. UI Event: Click "Stop" button in job_monitor.html
   ↓
2. job-monitor.js:stopJob(demandId)
   ↓
3. fetch('/api/pipeline/stop-alignment/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()
   ↓
5. viewer/utils/pipeline_utils.py:stop_job()
   ↓
6. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
7. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
8. OCS CLI stops job
   ↓
9. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
10. viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. Database updated (running_jobs → completed_jobs with status="ABORTED")
    ↓
12. Status returned to frontend
    ↓
13. job-monitor.js updates UI
```

### Auto-Proceed Workflow Call Stack

The complete auto-proceed workflow from alignment to post-QC:

```
1. UI Event: Enable Auto-Proceed toggle in submission modal
   ↓
2. pipeline-submit-modal.js:handleAutoProceedToggle()
   ↓
3. pipeline-final-modal.js:executeSubmission()
   ↓
4. fetch('/api/queue/import/')
   ↓
5. core/views.py:import_queue()
   ↓
6. Create two queue entries in queue_jobs table:
   - Alignment with status="Ready"
   - PostQC with status="PENDING"
   ↓
7. queue-management.js:processQueue()
   ↓
8. fetch('/api/queue/process/')
   ↓
9. core/views.py:process_queue()
   ↓
10. Submit alignment job via submit_sample_from_dashboard()
    ↓
11. Alignment job runs in OCS
    ↓
12. job-monitor.js timer triggers status update
    ↓
13. update_all_running_jobs()
    ↓
14. process_job_status_update() detects completed alignment
    ↓
15. process_auto_proceed_jobs(fastq_name)
    ↓
16. Find PENDING PostQC job for same FASTQ
    ↓
17. Update status from "PENDING" → "Ready"
    ↓
18. Next queue processing cycle:
    core/views.py:process_queue()
    ↓
19. Submit PostQC job via submit_sample_from_dashboard()
    ↓
20. PostQC job runs in OCS
    ↓
21. Process completes
```

### Failed Job Retry Call Stack

When a user retries a failed job:

```
1. UI Event: Click "Retry" button in failed_jobs.html
   ↓
2. Form submission to /api/pipeline/retry-failed-job/
   ↓
3. viewer/features/pipeline/pipeline.py:PipelineApiView.retry_failed_job()
   ↓
4. Get sample metadata from database
   ↓
5. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
6. Generate command and submit to OCS
   ↓
7. Update database:
   - Increment retry_count in Alignment/PostQC table
   - Update status to "SUBMITTED"
   - Remove record from failed_jobs table
   - Add to queue_jobs if necessary
   ↓
8. Return status to frontend
   ↓
9. Redirect to job_monitor.html
```

### Queue Management Call Stack

The queue processing workflow:

```
1. Timer Event: queue-management.js auto-processing timer triggers
   ↓
2. queue-management.js:processQueue()
   ↓
3. fetch('/api/queue/process/')
   ↓
4. core/views.py:process_queue()
   ↓
5. Check if max concurrent jobs reached:
   viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
6. Get next "Ready" job from queue_jobs table
   ↓
7. For each ready job:
   viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
8. On successful submission:
   - Remove from queue_jobs
   - Add to running_jobs
   - Update Alignment/PostQC table
   ↓
9. Return status to frontend
   ↓
10. queue-management.js updates UI
```

## UI Element to Backend Function Mapping

This section maps specific UI elements in the HTML templates to their JavaScript handlers and the corresponding backend functions they ultimately trigger. This direct tracing helps understand exactly how user interactions flow through the system.

### Dashboard Page (dashboard.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Submit Button | `submit-action-btn` | click | `pipeline-dashboard.js:handleSubmitAction()` | - | - |
| Sample Row Checkbox | `sample-checkbox-{id}` | change | `pipeline-dashboard.js:handleSampleSelection()` | - | - |
| Submit Selected | `submit-selected-btn` | click | `pipeline-dashboard.js:handleSubmitSelected()` | - | - |

### Submission Modal (pipeline-submit-modal.js)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Auto-Proceed Toggle | `auto-proceed-toggle` | change | `pipeline-submit-modal.js:handleAutoProceedToggle()` | - | - |
| Chemistry Dropdown | `chemistry-dropdown` | change | `pipeline-submit-modal.js:handleChemistryChange()` | - | `get_chemistry()` (equivalent) |
| Reference Dropdown | `reference-dropdown` | change | `pipeline-submit-modal.js:handleReferenceChange()` | - | `get_reference_name()` (equivalent) |
| Next Button | `submit-next-btn` | click | `pipeline-submit-modal.js:handleSubmission()` | - | - |

### Final Review Modal (pipeline-final-modal.js)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Execute Button | `execute-btn` | click | `pipeline-final-modal.js:executeSubmission()` | `/api/queue/import/` | `core/views.py:import_queue()` |
| Cancel Button | `cancel-btn` | click | `pipeline-final-modal.js:hide()` | - | - |
| Edit Commands Toggle | `edit-commands-toggle` | change | `pipeline-final-modal.js:toggleEditCommands()` | - | - |

### Job Monitor Page (job_monitor.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Refresh Button | `refreshNowBtn` | click | `job-monitor.js:refreshJobs()` | `/api/pipeline/get-job-data/` | `PipelineApiView.get_job_data()` → `count_running_jobs()` |
| Auto-Refresh Toggle | `autoRefreshToggle` | change | `job-monitor.js:toggleAutoRefresh()` | - | - |
| Update All Button | `updateAllBtn` | click | `job-monitor.js:refreshAllJobStatuses()` | `/api/pipeline/update_all_jobs/` | `PipelineApiView.update_all_jobs()` → `update_all_running_jobs()` |
| Check Status Button | `check-status-btn-{job_id}` | click | `job-monitor.js:checkJobStatus()` | `/api/pipeline/check-job-status/{id}/` | `PipelineApiView.check_job_status()` → `process_job_status_update()` → `check_job_status()` |
| Stop Job Button | `stop-job-btn-{job_id}` | click | `job-monitor.js:stopJob()` | `/api/pipeline/stop-alignment/{id}/` | `PipelineApiView.stop_alignment()` → `stop_job()` |

### Queue Management Page (queue_management.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Process Queue Button | `process-queue-btn` | click | `queue-management.js:processQueue()` | `/api/queue/process/` | `core/views.py:process_queue()` → `submit_sample_from_dashboard()` |
| Pause Queue Button | `pause-queue-btn` | click | `queue-management.js:toggleQueuePause()` | - | - |
| Refresh Queue Button | `refresh-queue-btn` | click | `queue-management.js:fetchQueueData()` | `/api/queue/get_data/` | `core/views.py:get_queue_data()` |
| Auto-Process Toggle | `auto-process-toggle` | change | `queue-management.js:toggleAutoProcessing()` | - | - |
| Remove Queue Item | `remove-queue-item-{id}` | click | `queue-management.js:removeQueueItem()` | `/api/queue/remove/{id}/` | `core/views.py:remove_queue_item()` |

### Failed Jobs Page (failed_jobs.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Retry Job Button | `retry-failed-job-{id}` | click | Form submission | `/api/pipeline/retry-failed-job/` | `PipelineApiView.retry_failed_job()` → `submit_sample_from_dashboard()` |
| Cancel Job Button | `cancel-failed-job-{id}` | click | Form submission | `/api/pipeline/cancel-failed-job/` | `PipelineApiView.cancel_failed_job()` |
| Job Type Filter | `job-type-filter` | change | `failed-jobs.js:filterJobs()` | - | - |
| Status Filter | `status-filter` | change | `failed-jobs.js:filterJobs()` | - | - |

### OCS Browser Page (ocs-browser.html)

| HTML Element | Element ID | Event | JavaScript Handler | API Endpoint | Backend Function |
|--------------|------------|-------|-------------------|--------------|------------------|
| Import Selected Button | `import-selected-btn` | click | `ocs-browser.js:importSelected()` | - | - |
| Sample Checkbox | `sample-checkbox-{id}` | change | `ocs-browser.js:handleSampleSelection()` | - | - |
| Save Selected Button | `save-selected-btn` | click | `ocs-browser.js:saveSelectedToPipeline()` | - | Stores in `pipeline-local-data.js` |

### DOM Element Detailed Tracing Examples

#### Job Status Checking Flow

When a user clicks the "Check Status" button for a job in the job monitor:

```
1. User clicks <button id="check-status-btn-12345" data-demand-id="demand-12345">Check Status</button>
   ↓
2. Event triggers job-monitor.js:checkJobStatus(demandId)
   ↓
3. JavaScript extracts demand_id from data-attribute
   ↓
4. fetch('/api/pipeline/check-job-status/demand-12345/', { method: 'POST' })
   ↓
5. Django routes to PipelineApiView.check_job_status(request, demand_id="demand-12345")
   ↓
6. process_job_status_update(demand_id="demand-12345")
   ↓
7. check_job_status(demand_id="demand-12345")
   ↓
8. OCS status check and database update
   ↓
9. Response to frontend
   ↓
10. job-monitor.js updates DOM: 
    - Status badge color changes
    - Toast notification appears
    - Row may disappear (if job completed)
```

#### Sample Submission Flow

When a user submits samples from the dashboard:

```
1. User selects samples with <input type="checkbox" class="sample-checkbox" id="sample-checkbox-123">
   ↓
2. User clicks <button id="submit-selected-btn">Submit Selected</button>
   ↓
3. Event triggers pipeline-dashboard.js:handleSubmitSelected()
   ↓
4. JavaScript retrieves selected sample IDs from checkboxes
   ↓
5. pipeline-submit-modal.js:openModal() displays modal with <div id="submission-modal">
   ↓
6. User configures options and toggles:
   - <select id="reference-dropdown">
   - <select id="chemistry-dropdown">
   - <input type="checkbox" id="auto-proceed-toggle">
   ↓
7. User clicks <button id="submit-next-btn">Next</button>
   ↓
8. Event triggers pipeline-submit-modal.js:handleSubmission()
   ↓
9. pipeline-final-modal.js:show() displays final review modal
   ↓
10. User clicks <button id="execute-btn">Execute</button>
    ↓
11. Event triggers pipeline-final-modal.js:executeSubmission()
    ↓
12. fetch('/api/queue/import/', { method: 'POST', body: JSON.stringify(commands) })
    ↓
13. Django routes to core/views.py:import_queue()
    ↓
14. Database updates (queue_jobs table)
    ↓
15. Success message displayed in UI
```

#### Auto-Proceed Toggle Effect

The auto-proceed toggle has a specific flow that affects how jobs progress:

```
1. User toggles <input type="checkbox" id="auto-proceed-toggle">
   ↓
2. Event triggers pipeline-submit-modal.js:handleAutoProceedToggle()
   ↓
3. JavaScript stores setting in local state
   ↓
4. When final submission happens with pipeline-final-modal.js:executeSubmission()
   ↓
5. If auto-proceed is enabled:
   - Alignment command marked with status="Ready"
   - PostQC command marked with status="PENDING"
   ↓
6. Both sent to backend in fetch('/api/queue/import/')
   ↓
7. core/views.py:import_queue() creates two entries in queue_jobs
   ↓
8. Only the "Ready" alignment job is processed initially
   ↓
9. When alignment completes:
   process_job_status_update() → process_auto_proceed_jobs()
   ↓
10. process_auto_proceed_jobs() updates PostQC status from "PENDING" to "Ready"
    ↓
11. Next queue processing cycle picks up the now-Ready PostQC job
```

#### Job Status Monitoring Loop

```
JobMonitorView.__init__() creates page context
↓
job-monitor.js initializes with autoRefreshInterval
↓                                             ↑
job-monitor.js:refreshJobs()                  |
↓                                             |
fetch('/api/pipeline/get-job-data/')          |
↓                                             |
PipelineApiView.get_job_data()                |
↓                                             |
count_running_jobs() and database queries     |
↓                                             |
Return data to frontend                       |
↓                                             |
job-monitor.js updates UI tables and badges   |
↓                                             |
Wait for next interval ----------------------→|
```

### Frontend Component Details

#### job-monitor.js

This JavaScript file is responsible for the job monitoring interface. Key features:

1. **Automatic Refresh**: Sets up intervals to refresh job data automatically
   ```javascript
   // job-monitor.js
   startAutoRefresh() {
     this.autoRefreshInterval = setInterval(() => {
       this.refreshJobs(false);
     }, this.autoRefreshTime);
   }
   ```

2. **Manual Refresh**: Handles user-triggered refresh of job data
   ```javascript
   // job-monitor.js
   refreshJobs(showSuccessToast = false) {
     // Uses fetch() to call /api/pipeline/get-job-data/
     // This triggers count_running_jobs() on the backend
   }
   ```

3. **Status Checking**: Provides UI for checking individual job status
   ```javascript
   // job-monitor.js
   checkJobStatus(demandId) {
     // Uses fetch() to call /api/pipeline/check-job-status/{demandId}/
     // This triggers check_job_status() on the backend
   }
   ```

4. **Job Stopping**: Allows users to stop running jobs
   ```javascript
   // job-monitor.js
   stopJob(demandId) {
     // Uses fetch() to call /api/pipeline/stop-alignment/{demandId}/
     // This triggers stop_job() on the backend
   }
   ```

#### queue-management.js

This JavaScript file handles the queue management interface. Key features:

1. **Queue Fetching**: Retrieves queue data from the server
   ```javascript
   // queue-management.js
   fetchQueueData() {
     // Uses fetch() to call /api/queue/get_data/
     // Displays queue items with pagination
   }
   ```

2. **Auto Processing**: Sets up automatic processing of queued jobs
   ```javascript
   // queue-management.js
   startAutoProcessing() {
     // Sets up timer to call processQueue() automatically
   }
   
   processQueue() {
     // Uses fetch() to call /api/queue/process/
     // This triggers submit_sample_from_dashboard() for Ready jobs
   }
   ```

3. **Queue Control**: Provides UI for pausing/resuming queue processing
   ```javascript
   // queue-management.js
   toggleQueuePause() {
     // Pauses or resumes automatic queue processing
   }
   ```

#### pipeline-submit-modal.js

This JavaScript file handles the submission modal interface. Key features:

1. **Command Generation**: Creates commands based on selected options
   ```javascript
   // pipeline-submit-modal.js
   generateAlignmentCommand(sample) {
     // Frontend equivalent of create_mtx_alignment_command/create_rtx_alignment_command
   }
   ```

2. **Workflow Determination**: Identifies workflow type based on sample data
   ```javascript
   // pipeline-submit-modal.js
   determineWorkflow(sample, options = {}) {
     // Frontend equivalent of determine_workflow()
   }
   ```

3. **Reference/Chemistry Selection**: Provides dropdowns for reference and chemistry
   ```javascript
   // pipeline-submit-modal.js
   getReference(organism) {
     // Frontend equivalent of get_reference_name()
   }
   
   getChemistry(libraryPrep) {
     // Frontend equivalent of get_chemistry()
   }
   ```

#### pipeline-final-modal.js

This JavaScript file handles the final review and execution interface. Key features:

1. **Command Display**: Shows final commands for user review
   ```javascript
   // pipeline-final-modal.js
   show(data) {
     // Displays alignment and post-QC commands for review
   }
   ```

2. **Job Submission**: Submits commands to the queue for processing
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // Uses fetch() to call /api/queue/import/
     // Creates entries in queue_jobs table
   }
   ```

3. **Auto-Proceed Setup**: Handles setting up auto-proceed workflow
   ```javascript
   // pipeline-final-modal.js
   executeSubmission() {
     // If auto-proceed enabled, marks PostQC jobs with PENDING status
   }
   ```

### HTML View Templates

#### dashboard.html

The dashboard template displays the main pipeline dashboard with:
- Sample selection table
- Submit button that triggers the submission modal
- Job statistics powered by `count_running_jobs()`

#### job_monitor.html

The job monitor template displays:
- Running jobs table
- Completed jobs table
- Job status counts
- Auto-refresh toggle
- Refresh button
- Check status and stop buttons for individual jobs

#### queue_management.html

The queue management template displays:
- Queue items table
- Process queue button
- Pause/resume queue button
- Auto-processing settings
- Queue statistics

#### failed_jobs.html

The failed jobs template displays:
- Failed jobs table with retry and cancel options
- Failure details
- Retry buttons that trigger `PipelineApiView.retry_failed_job()`

### Database Tables and Models Integration

The following database models are essential to the pipeline system:

1. **RunningJob**: Stores currently running jobs
   - Used by `process_job_status_update()` to track job status
   - Updated by `move_job_to_destination_table()`

2. **CompletedJob**: Stores successfully completed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in job_monitor.html

3. **FailedJob**: Stores failed jobs
   - Populated by `move_job_to_destination_table()`
   - Displayed in failed_jobs.html

4. **QueueJobs**: Stores jobs waiting to be processed
   - Created by `pipeline-final-modal.js:executeSubmission()`
   - Processed by `process_queue()`
   - Updated by `process_auto_proceed_jobs()`

## Call Stack Diagrams

This section provides detailed call stack diagrams for key workflows in the pipeline system, showing the exact sequence of function calls from UI events through the backend pipeline.

### Job Submission Call Stack

When a user submits samples for processing via the Pipeline Dashboard:

```
1. UI Event: Click "Submit" button in dashboard.html
   ↓
2. pipeline-dashboard.js:handleSubmitAction()
   ↓
3. pipeline-submit-modal.js:openModal()
   ↓
4. User configures options and clicks "Next"
   ↓
5. pipeline-submit-modal.js:handleSubmission()
   ↓
6. pipeline-final-modal.js:show()
   ↓
7. User clicks "Execute"
   ↓
8. pipeline-final-modal.js:executeSubmission()
   ↓
9. fetch('/api/queue/import/')
   ↓
10. core/views.py:import_queue()
    ↓
11. Add jobs to queue_jobs table
    ↓
12. queue-management.js:processQueue()
    ↓
13. fetch('/api/queue/process/')
    ↓
14. core/views.py:process_queue()
    ↓
15. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
    ↓
16. viewer/utils/pipeline_utils.py:determine_workflow()
    ↓
17. If MTX: viewer/utils/pipeline_utils.py:create_mtx_alignment_command()
    If RTX: viewer/utils/pipeline_utils.py:create_rtx_alignment_command()
    ↓
18. viewer/utils/pipeline_utils.py:create_bash_script()
    ↓
19. viewer/utils/pipeline_utils.py:run_bash_script()
    ↓
20. OCS CLI submits job
    ↓
21. Job ID returned and saved to database
```

### Job Status Checking Call Stack

When a user checks the status of a specific job:

```
1. UI Event: Click "Check Status" button in job_monitor.html
   ↓
2. job-monitor.js:checkJobStatus(demandId)
   ↓
3. fetch('/api/pipeline/check-job-status/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.check_job_status()
   ↓
5. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
6. viewer/utils/pipeline_utils.py:check_job_status()
   ↓
7. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
8. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
9. Parse OCS CLI output
   ↓
10. If job complete/failed:
    viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. If alignment completed successfully:
    viewer/utils/pipeline_utils.py:process_auto_proceed_jobs()
    ↓
12. Database updated (running_jobs, completed_jobs, failed_jobs tables)
    ↓
13. Status returned to frontend
    ↓
14. job-monitor.js updates UI
```

### Auto-Refresh Job Status Call Stack

The background job status update process:

```
1. Timer Event: job-monitor.js:autoRefreshInterval triggers
   ↓
2. job-monitor.js:refreshJobs()
   ↓
3. fetch('/api/pipeline/get-job-data/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.get_job_data()
   ↓
5. viewer/features/pipeline/pipeline.py:JobMonitorView._get_fresh_job_data()
   ↓
6. viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
7. Periodically (less frequently):
   job-monitor.js:refreshAllJobStatuses()
   ↓
8. fetch('/api/pipeline/update_all_jobs/')
   ↓
9. viewer/features/pipeline/pipeline.py:PipelineApiView.update_all_jobs()
   ↓
10. viewer/utils/pipeline_utils.py:update_all_running_jobs()
    ↓
11. For each running job:
    viewer/utils/pipeline_utils.py:process_job_status_update()
    ↓
12. Database updated
    ↓
13. Fresh data returned to frontend
    ↓
14. job-monitor.js updates UI tables and counts
```

### Stop Job Call Stack

When a user stops a running job:

```
1. UI Event: Click "Stop" button in job_monitor.html
   ↓
2. job-monitor.js:stopJob(demandId)
   ↓
3. fetch('/api/pipeline/stop-alignment/{demandId}/')
   ↓
4. viewer/features/pipeline/pipeline.py:PipelineApiView.stop_alignment()
   ↓
5. viewer/utils/pipeline_utils.py:stop_job()
   ↓
6. viewer/utils/pipeline_utils.py:create_bash_script()
   ↓
7. viewer/utils/pipeline_utils.py:run_bash_script()
   ↓
8. OCS CLI stops job
   ↓
9. viewer/utils/pipeline_utils.py:process_job_status_update()
   ↓
10. viewer/utils/pipeline_utils.py:move_job_to_destination_table()
    ↓
11. Database updated (running_jobs → completed_jobs with status="ABORTED")
    ↓
12. Status returned to frontend
    ↓
13. job-monitor.js updates UI
```

### Auto-Proceed Workflow Call Stack

The complete auto-proceed workflow from alignment to post-QC:

```
1. UI Event: Enable Auto-Proceed toggle in submission modal
   ↓
2. pipeline-submit-modal.js:handleAutoProceedToggle()
   ↓
3. pipeline-final-modal.js:executeSubmission()
   ↓
4. fetch('/api/queue/import/')
   ↓
5. core/views.py:import_queue()
   ↓
6. Create two queue entries in queue_jobs table:
   - Alignment with status="Ready"
   - PostQC with status="PENDING"
   ↓
7. queue-management.js:processQueue()
   ↓
8. fetch('/api/queue/process/')
   ↓
9. core/views.py:process_queue()
   ↓
10. Submit alignment job via submit_sample_from_dashboard()
    ↓
11. Alignment job runs in OCS
    ↓
12. job-monitor.js timer triggers status update
    ↓
13. update_all_running_jobs()
    ↓
14. process_job_status_update() detects completed alignment
    ↓
15. process_auto_proceed_jobs(fastq_name)
    ↓
16. Find PENDING PostQC job for same FASTQ
    ↓
17. Update status from "PENDING" → "Ready"
    ↓
18. Next queue processing cycle:
    core/views.py:process_queue()
    ↓
19. Submit PostQC job via submit_sample_from_dashboard()
    ↓
20. PostQC job runs in OCS
    ↓
21. Process completes
```

### Failed Job Retry Call Stack

When a user retries a failed job:

```
1. UI Event: Click "Retry" button in failed_jobs.html
   ↓
2. Form submission to /api/pipeline/retry-failed-job/
   ↓
3. viewer/features/pipeline/pipeline.py:PipelineApiView.retry_failed_job()
   ↓
4. Get sample metadata from database
   ↓
5. viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
6. Generate command and submit to OCS
   ↓
7. Update database:
   - Increment retry_count in Alignment/PostQC table
   - Update status to "SUBMITTED"
   - Remove record from failed_jobs table
   - Add to queue_jobs if necessary
   ↓
8. Return status to frontend
   ↓
9. Redirect to job_monitor.html
```

### Queue Management Call Stack

The queue processing workflow:

```
1. Timer Event: queue-management.js auto-processing timer triggers
   ↓
2. queue-management.js:processQueue()
   ↓
3. fetch('/api/queue/process/')
   ↓
4. core/views.py:process_queue()
   ↓
5. Check if max concurrent jobs reached:
   viewer/utils/pipeline_utils.py:count_running_jobs()
   ↓
6. Get next "Ready" job from queue_jobs table
   ↓
7. For each ready job:
   viewer/utils/pipeline_utils.py:submit_sample_from_dashboard()
   ↓
8. On successful submission:
   - Remove from queue_jobs
   - Add to running_jobs
   - Update Alignment/PostQC table
   ↓
9. Return status to frontend
   ↓
10. queue-management.js updates UI
```

## Error Handling

Most functions in this module include comprehensive error handling with detailed logging. The general pattern is:

1. Try to execute the operation
2. Log success or failure with appropriate detail
3. Return a structured result with status information

This allows calling code to easily determine if an operation succeeded or failed and take appropriate action.

## Logging

The module uses the standard Python logging system. All functions log their operations with appropriate log levels:

- `logger.debug()`: Detailed diagnostic information
- `logger.info()`: Confirmation that things are working as expected
- `logger.warning()`: Indication that something unexpected happened
- `logger.error()`: Serious problem that prevented operation from completing
- `logger.exception()`: Error occurred with full traceback

## Workflow Transitions

The module handles workflow transitions, particularly the "auto-proceed" functionality that automatically advances samples from alignment to post-QC processing when alignment completes successfully.

## Testing Mode

The script execution functionality includes a test mode that can be enabled by setting the `TEST_MODE` environment variable to `'true'`. In test mode, commands that would submit jobs to OCS are logged instead of executed, and mock responses are returned. 
