"""
Unit tests for Task database model
"""
import pytest
from datetime import datetime
from src.app import db, Task


class TestTaskModel:
    """Tests for the Task model"""
    
    def test_create_task_model(self, app):
        """Test creating a Task model instance"""
        with app.app_context():
            task = Task(
                title='Test Task',
                description='Test Description',
                status='pending'
            )
            
            assert task.title == 'Test Task'
            assert task.description == 'Test Description'
            assert task.status == 'pending'
    
    def test_task_default_status(self, app):
        """Test that default status is 'pending'"""
        with app.app_context():
            task = Task(title='Task with default status')
            db.session.add(task)
            db.session.commit()
            
            assert task.status == 'pending'
    
    def test_task_to_dict(self, app):
        """Test converting task to dictionary"""
        with app.app_context():
            task = Task(
                title='Dict Task',
                description='Convert to dict',
                status='completed'
            )
            db.session.add(task)
            db.session.commit()
            
            task_dict = task.to_dict()
            
            assert isinstance(task_dict, dict)
            assert task_dict['title'] == 'Dict Task'
            assert task_dict['description'] == 'Convert to dict'
            assert task_dict['status'] == 'completed'
            assert 'id' in task_dict
            assert 'created_at' in task_dict
            assert isinstance(task_dict['created_at'], str)
    
    def test_task_created_at_auto_set(self, app):
        """Test that created_at is automatically set"""
        with app.app_context():
            task = Task(title='Timestamp Task')
            db.session.add(task)
            db.session.commit()
            
            assert task.created_at is not None
            assert isinstance(task.created_at, datetime)
    
    def test_task_persistence(self, app):
        """Test saving and retrieving a task from database"""
        with app.app_context():
            # Create and save task
            task = Task(
                title='Persistent Task',
                description='Should persist in DB',
                status='pending'
            )
            db.session.add(task)
            db.session.commit()
            
            task_id = task.id
            
            # Retrieve task
            retrieved_task = Task.query.get(task_id)
            
            assert retrieved_task is not None
            assert retrieved_task.title == 'Persistent Task'
            assert retrieved_task.description == 'Should persist in DB'
            assert retrieved_task.status == 'pending'
    
    def test_task_update(self, app):
        """Test updating a task in database"""
        with app.app_context():
            # Create task
            task = Task(title='Original Title', status='pending')
            db.session.add(task)
            db.session.commit()
            
            task_id = task.id
            
            # Update task
            task.title = 'Updated Title'
            task.status = 'completed'
            db.session.commit()
            
            # Retrieve and verify
            updated_task = Task.query.get(task_id)
            assert updated_task.title == 'Updated Title'
            assert updated_task.status == 'completed'
    
    def test_task_delete(self, app):
        """Test deleting a task from database"""
        with app.app_context():
            # Create task
            task = Task(title='Task to Delete')
            db.session.add(task)
            db.session.commit()
            
            task_id = task.id
            
            # Delete task
            db.session.delete(task)
            db.session.commit()
            
            # Verify deletion
            deleted_task = Task.query.get(task_id)
            assert deleted_task is None
    
    def test_query_all_tasks(self, app):
        """Test querying all tasks"""
        with app.app_context():
            # Create multiple tasks
            tasks = [
                Task(title='Task 1'),
                Task(title='Task 2'),
                Task(title='Task 3'),
            ]
            
            for task in tasks:
                db.session.add(task)
            db.session.commit()
            
            # Query all
            all_tasks = Task.query.all()
            
            assert len(all_tasks) == 3
            assert all_tasks[0].title == 'Task 1'
            assert all_tasks[1].title == 'Task 2'
            assert all_tasks[2].title == 'Task 3'
    
    def test_filter_tasks_by_status(self, app):
        """Test filtering tasks by status"""
        with app.app_context():
            # Create tasks with different statuses
            tasks = [
                Task(title='Pending 1', status='pending'),
                Task(title='Completed 1', status='completed'),
                Task(title='Pending 2', status='pending'),
                Task(title='Completed 2', status='completed'),
            ]
            
            for task in tasks:
                db.session.add(task)
            db.session.commit()
            
            # Query pending tasks
            pending_tasks = Task.query.filter_by(status='pending').all()
            assert len(pending_tasks) == 2
            
            # Query completed tasks
            completed_tasks = Task.query.filter_by(status='completed').all()
            assert len(completed_tasks) == 2
