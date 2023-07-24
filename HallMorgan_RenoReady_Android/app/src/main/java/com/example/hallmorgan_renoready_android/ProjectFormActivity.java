package com.example.hallmorgan_renoready_android;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.util.Pair;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;

import com.example.hallmorgan_renoready_android.fragments.TaskListFragment;
import com.example.hallmorgan_renoready_android.helperClasses.HelperMethods;
import com.example.hallmorgan_renoready_android.objects.Project;
import com.example.hallmorgan_renoready_android.objects.Task;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.WriteBatch;

import java.util.ArrayList;

public class ProjectFormActivity extends AppCompatActivity implements TaskListFragment.TaskListener {
    private static final String TAG = "ProjectFormActivity";

    private EditText projectTitle_et;
    private Button projectCategoryButton;
    private String category = "KITCHEN";
    private EditText budget_et;
    private ArrayList<Task> tasks = new ArrayList<>();
    private ImageView categoryIcon;
    private ArrayList<String> taskIds = new ArrayList<>();

    private Project project;
    private final FirebaseFirestore db = FirebaseFirestore.getInstance();

    private static final String[] categories = {"BATHROOM", "BEDROOM", "KITCHEN", "LIVING ROOM"};



    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_project_form);

        projectTitle_et = findViewById(R.id.project_name_et);
        projectCategoryButton = findViewById(R.id.category_button);
        categoryIcon = findViewById(R.id.category_icon);
        budget_et = findViewById(R.id.budget_et);

        Intent startingIntent = getIntent();
        if (startingIntent != null){
            project = (Project) startingIntent.getSerializableExtra(ProjectDetailsActivity.EXTRA_PROJECT);
            updateUIWithProject();
            getSupportFragmentManager().beginTransaction().replace(R.id.taskList_fragment_container_form, TaskListFragment.newInstance(project)).commit();
        } else {
            getSupportFragmentManager().beginTransaction().replace(R.id.taskList_fragment_container_form, TaskListFragment.newInstance(null)).commit();
            tasks = new ArrayList<>();
            taskIds = new ArrayList<>();
        }

        projectCategoryButton.setOnClickListener(view -> new AlertDialog.Builder(ProjectFormActivity.this).setTitle("Choose Category:").setItems(categories, (dialogInterface, which) -> {
            category = categories[which];
            projectCategoryButton.setText(category);
            updateImageIcon();
        }).show());

    }

    private void updateImageIcon() {
        switch (category){
            case "BATHROOM":
                categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(getResources(),R.drawable.bathroom, null));
                break;
            case "BEDROOM":
                categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(getResources(),R.drawable.bedroom, null));
                break;
            case "KITCHEN":
                categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(getResources(),R.drawable.kitchen, null));
                break;
            case "LIVING ROOM":
                categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(getResources(),R.drawable.livingroom, null));
                break;
        }
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.form_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.save_action){
            verifyEntries();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void verifyEntries() {
        Pair<Boolean, String> titleCheck = HelperMethods.textNotEmpty(projectTitle_et);
        Pair<Boolean, String> budgetCheck = HelperMethods.textNotEmpty(budget_et);

        if (!titleCheck.first || !budgetCheck.first) {
            Toast.makeText(this, "Project title and budget cannot be left blank", Toast.LENGTH_SHORT).show();
            //Do nothing
        } else {
            String title = titleCheck.second;
            String budgetStr = budgetCheck.second.replaceAll("[^\\d.]", "");
            double budget;

            try {
                budget = Double.parseDouble(budgetStr);
            } catch (NumberFormatException e) {
                // Handle case where string couldn't be converted to double
                Toast.makeText(this, "Invalid input for budget.", Toast.LENGTH_SHORT).show();
                return;
            }

            if (project == null){
                //New project
                project = new Project();
                project.setProjectID("");
                project.setTitle(title);
                project.setCategory(category);
                project.setBudget(budget);
                if (taskIds != null && !taskIds.isEmpty()){
                    project.setTaskIds(taskIds);
                }
                if (tasks != null && !tasks.isEmpty()){
                    project.setTasks(tasks);
                }

                addProjectToFirestore();
            } else {
                //Updating existing project
                project.setTitle(title);
                project.setCategory(category);
                project.setBudget(budget);
                project.setTaskIds(taskIds);
                project.setTasks(tasks);
                updateProjectInFirestore();
            }
        }
    }

    private void updateProjectInFirestore() {
        db.collection("projects").document(project.getProjectID())
                .set(project)
                .addOnSuccessListener(aVoid -> {
                    Log.d(TAG, "Project updated with ID: " + project.getProjectID());
                    goToDetails();
                })
                .addOnFailureListener(e -> Log.w(TAG, "Error updating project", e));
    }

    private void addProjectToFirestore() {
        // Get a new document reference with a generated ID
        FirebaseAuth auth = FirebaseAuth.getInstance();
        FirebaseUser user = auth.getCurrentUser();
        DocumentReference newProjectRef = db.collection("projects").document();
        // Set the project ID before saving the project
        project.setProjectID(newProjectRef.getId());
        project.setTasks(tasks);
        project.setTaskIds(taskIds);
        newProjectRef.set(project)
                .addOnSuccessListener(aVoid -> {
                    String projectId = newProjectRef.getId();
                    Log.d(TAG, "Project added with ID: " + projectId);

                    // Update user's projects array
                    // Replace "userId" with the actual ID of the user
                    if (user != null){
                        DocumentReference userRef = db.collection("users").document(user.getUid());
                        userRef.update("projects", FieldValue.arrayUnion(projectId));
                        goToDetails();
                    }

                })
                .addOnFailureListener(e -> Log.w(TAG, "Error adding project", e));
    }



    private void goToDetails() {
        if (project != null){
            Intent intent = new Intent(this, ProjectDetailsActivity.class);
            intent.putExtra(ProjectDetailsActivity.EXTRA_PROJECT, project);
            startActivity(intent);
        }
    }

    private void updateUIWithProject() {
        if (project != null){
            projectTitle_et.setText(project.getTitle());
            projectCategoryButton.setText(project.getCategory());
            String budget = String.valueOf(project.getBudget());
            budget_et.setText(budget);
            if (project.getTasks() != null && !project.getTasks().isEmpty() && project.getTaskIds() != null && !project.getTaskIds().isEmpty()){
                tasks = project.getTasks();
                taskIds = project.getTaskIds();
            } else {
                tasks = new ArrayList<>();
                taskIds = new ArrayList<>();
            }
        }
    }

    @Override
    public void addTaskToFirestore(Task task) {
        Log.d(TAG, "Task object: " + task.toString());
        DocumentReference newTaskRef = db.collection("tasks").document();
        // Set the task ID before saving the task
        task.setTaskId(newTaskRef.getId());

        newTaskRef.set(task).addOnSuccessListener(aVoid -> {
            String newTaskId = newTaskRef.getId();
            task.setTaskId(newTaskId);
            Log.d(TAG, "Task successfully added with ID: " + newTaskId);

            tasks.add(task);  // add the task to the activity's list of tasks
            taskIds.add(newTaskId);
            // Update the task in Firestore
            newTaskRef.set(task);  // Only call set() here, after adding the ID to the Task object

        }).addOnFailureListener(e -> Log.d(TAG, "Error adding task", e));
    }



    @Override
    public void deleteTasksFromFirestore(ArrayList<Task> tasks) {
        WriteBatch batch = db.batch();

        for (Task task : tasks) {
            DocumentReference taskRef = db.collection("tasks").document(task.getTaskId());
            batch.delete(taskRef);
        }

        batch.commit().addOnSuccessListener(aVoid -> Log.d(TAG, "Tasks successfully deleted")).addOnFailureListener(e -> Log.d(TAG, "Error deleting tasks", e));
    }
}
