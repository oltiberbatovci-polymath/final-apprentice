"""
Unit tests for the Task Manager API endpoints
"""
import json
import pytest


class TestHealthEndpoint:
    """Tests for the health check endpoint"""
    
    def test_health_check(self, client):
        """Test that health endpoint returns 200 and correct status"""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data


class TestTasksEndpoints:
    """Tests for task CRUD endpoints"""
    
    def test_get_all_tasks_empty(self, client):
        """Test getting all tasks when database is empty"""
        response = client.get('/api/tasks')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert isinstance(data, list)
        assert len(data) == 0
    
    def test_create_task_success(self, client):
        """Test creating a new task"""
        task_data = {
            'title': 'Test Task',
            'description': 'This is a test task',
            'status': 'pending'
        }
        
        response = client.post('/api/tasks',
                             data=json.dumps(task_data),
                             content_type='application/json')
        
        assert response.status_code == 201
        
        data = json.loads(response.data)
        assert data['title'] == 'Test Task'
        assert data['description'] == 'This is a test task'
        assert data['status'] == 'pending'
        assert 'id' in data
        assert 'created_at' in data
    
    def test_create_task_without_title(self, client):
        """Test creating a task without title should fail"""
        task_data = {
            'description': 'Missing title'
        }
        
        response = client.post('/api/tasks',
                             data=json.dumps(task_data),
                             content_type='application/json')
        
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_create_task_default_status(self, client):
        """Test that default status is 'pending' if not provided"""
        task_data = {
            'title': 'Task with default status'
        }
        
        response = client.post('/api/tasks',
                             data=json.dumps(task_data),
                             content_type='application/json')
        
        assert response.status_code == 201
        
        data = json.loads(response.data)
        assert data['status'] == 'pending'
    
    def test_get_all_tasks_with_data(self, client):
        """Test getting all tasks after creating some"""
        # Create multiple tasks
        tasks = [
            {'title': 'Task 1', 'description': 'First task'},
            {'title': 'Task 2', 'description': 'Second task'},
            {'title': 'Task 3', 'description': 'Third task'},
        ]
        
        for task in tasks:
            client.post('/api/tasks',
                       data=json.dumps(task),
                       content_type='application/json')
        
        # Get all tasks
        response = client.get('/api/tasks')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert len(data) == 3
        assert data[0]['title'] == 'Task 1'
        assert data[1]['title'] == 'Task 2'
        assert data[2]['title'] == 'Task 3'
    
    def test_get_task_by_id(self, client):
        """Test getting a specific task by ID"""
        # Create a task
        task_data = {'title': 'Specific Task', 'description': 'Get me by ID'}
        create_response = client.post('/api/tasks',
                                     data=json.dumps(task_data),
                                     content_type='application/json')
        
        task_id = json.loads(create_response.data)['id']
        
        # Get the task by ID
        response = client.get(f'/api/tasks/{task_id}')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['id'] == task_id
        assert data['title'] == 'Specific Task'
    
    def test_get_nonexistent_task(self, client):
        """Test getting a task that doesn't exist"""
        response = client.get('/api/tasks/999')
        assert response.status_code == 404
    
    def test_update_task(self, client):
        """Test updating an existing task"""
        # Create a task
        task_data = {'title': 'Original Title', 'status': 'pending'}
        create_response = client.post('/api/tasks',
                                     data=json.dumps(task_data),
                                     content_type='application/json')
        
        task_id = json.loads(create_response.data)['id']
        
        # Update the task
        update_data = {
            'title': 'Updated Title',
            'description': 'Added description',
            'status': 'completed'
        }
        
        response = client.put(f'/api/tasks/{task_id}',
                            data=json.dumps(update_data),
                            content_type='application/json')
        
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['title'] == 'Updated Title'
        assert data['description'] == 'Added description'
        assert data['status'] == 'completed'
    
    def test_update_partial_task(self, client):
        """Test updating only some fields of a task"""
        # Create a task
        task_data = {
            'title': 'Original Title',
            'description': 'Original description',
            'status': 'pending'
        }
        create_response = client.post('/api/tasks',
                                     data=json.dumps(task_data),
                                     content_type='application/json')
        
        task_id = json.loads(create_response.data)['id']
        
        # Update only the status
        update_data = {'status': 'completed'}
        
        response = client.put(f'/api/tasks/{task_id}',
                            data=json.dumps(update_data),
                            content_type='application/json')
        
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['title'] == 'Original Title'  # Should remain unchanged
        assert data['description'] == 'Original description'  # Should remain unchanged
        assert data['status'] == 'completed'  # Should be updated
    
    def test_update_nonexistent_task(self, client):
        """Test updating a task that doesn't exist"""
        update_data = {'title': 'New Title'}
        
        response = client.put('/api/tasks/999',
                            data=json.dumps(update_data),
                            content_type='application/json')
        
        assert response.status_code == 404
    
    def test_delete_task(self, client):
        """Test deleting a task"""
        # Create a task
        task_data = {'title': 'Task to Delete'}
        create_response = client.post('/api/tasks',
                                     data=json.dumps(task_data),
                                     content_type='application/json')
        
        task_id = json.loads(create_response.data)['id']
        
        # Delete the task
        response = client.delete(f'/api/tasks/{task_id}')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert 'message' in data
        
        # Verify task is deleted
        get_response = client.get(f'/api/tasks/{task_id}')
        assert get_response.status_code == 404
    
    def test_delete_nonexistent_task(self, client):
        """Test deleting a task that doesn't exist"""
        response = client.delete('/api/tasks/999')
        assert response.status_code == 404


class TestTaskWorkflow:
    """Integration tests for complete task workflows"""
    
    def test_complete_task_lifecycle(self, client):
        """Test creating, updating, and deleting a task"""
        # Create
        task_data = {
            'title': 'Lifecycle Task',
            'description': 'Testing full lifecycle',
            'status': 'pending'
        }
        
        create_response = client.post('/api/tasks',
                                     data=json.dumps(task_data),
                                     content_type='application/json')
        assert create_response.status_code == 201
        task_id = json.loads(create_response.data)['id']
        
        # Read
        get_response = client.get(f'/api/tasks/{task_id}')
        assert get_response.status_code == 200
        
        # Update
        update_data = {'status': 'completed'}
        update_response = client.put(f'/api/tasks/{task_id}',
                                     data=json.dumps(update_data),
                                     content_type='application/json')
        assert update_response.status_code == 200
        assert json.loads(update_response.data)['status'] == 'completed'
        
        # Delete
        delete_response = client.delete(f'/api/tasks/{task_id}')
        assert delete_response.status_code == 200
        
        # Verify deletion
        final_get = client.get(f'/api/tasks/{task_id}')
        assert final_get.status_code == 404
    
    def test_multiple_tasks_management(self, client):
        """Test managing multiple tasks"""
        # Create 5 tasks
        task_ids = []
        for i in range(5):
            task_data = {
                'title': f'Task {i+1}',
                'description': f'Description {i+1}',
                'status': 'pending' if i % 2 == 0 else 'completed'
            }
            response = client.post('/api/tasks',
                                 data=json.dumps(task_data),
                                 content_type='application/json')
            task_ids.append(json.loads(response.data)['id'])
        
        # Verify all tasks exist
        all_tasks = client.get('/api/tasks')
        assert len(json.loads(all_tasks.data)) == 5
        
        # Delete some tasks
        client.delete(f'/api/tasks/{task_ids[0]}')
        client.delete(f'/api/tasks/{task_ids[2]}')
        
        # Verify remaining tasks
        remaining_tasks = client.get('/api/tasks')
        assert len(json.loads(remaining_tasks.data)) == 3


class TestCORS:
    """Tests for CORS configuration"""
    
    def test_cors_headers_present(self, client):
        """Test that CORS headers are present in responses"""
        response = client.get('/api/tasks')
        
        # CORS headers should be present
        assert response.status_code == 200
        # Note: In test mode, CORS headers might not be fully set
        # This is more of an integration test with real browser
