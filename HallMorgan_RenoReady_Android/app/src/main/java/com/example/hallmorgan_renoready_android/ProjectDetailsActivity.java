package com.example.hallmorgan_renoready_android;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;

import com.example.hallmorgan_renoready_android.fragments.TaskListFragment;
import com.example.hallmorgan_renoready_android.objects.Project;
import com.example.hallmorgan_renoready_android.objects.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.WriteBatch;

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class ProjectDetailsActivity extends AppCompatActivity implements TaskListFragment.TaskListener {
    public static final String EXTRA_PROJECT = "com.example.hallmorgan_renoready_android.EXTRA_PROJECT";
    private static final String TAG = "ProjectDetailsActivity";

    private TextView projectTitle;
    private ImageView categoryIcon;
    private TextView projectBudget;

    private final FirebaseFirestore db = FirebaseFirestore.getInstance();

    private Project project;

    private ArrayList<Task> tasks;
    private ArrayList<String> taskIDs = new ArrayList<>();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_project_detail);
        projectTitle = findViewById(R.id.project_title_label_details);
        projectBudget = findViewById(R.id.project_budget_details);
        categoryIcon = findViewById(R.id.category_icon_details);

        Intent startingIntent = getIntent();
        if (startingIntent != null){
            project = (Project) startingIntent.getSerializableExtra(EXTRA_PROJECT);
            if (project != null){
                if (project.getTaskIds() != null && !project.getTaskIds().isEmpty()){
                    getTasks(project.getTaskIds());
                }
                updateUI();
            }
        }
    }



    private void getTasks(ArrayList<String> taskIds){
        FirebaseFirestore db = FirebaseFirestore.getInstance();
        tasks = new ArrayList<>();
        List<com.google.android.gms.tasks.Task<DocumentSnapshot>> taskFetchTasks = new ArrayList<>();

        for (String taskId : taskIds) {
            DocumentReference taskRef = db.collection("tasks").document(taskId);
            com.google.android.gms.tasks.Task<DocumentSnapshot> firestoreTask = taskRef.get();
            taskFetchTasks.add(firestoreTask);
        }

        Tasks.whenAllSuccess(taskFetchTasks).addOnSuccessListener(list -> {
            for (Object object : list) {
                DocumentSnapshot taskDocument = (DocumentSnapshot) object;
                if (taskDocument.exists()){
                    Task task = taskDocument.toObject(Task.class);
                    if (task != null){
                        //Add tasks to the array
                        tasks.add(task);
                    }
                } else {
                    Log.d(TAG, "onComplete: No such task");
                }
            }
            updateUI();
        }).addOnFailureListener(e -> {
            if (e != null){
                Log.d(TAG, "onComplete: get failed with ", e);
            }
        });
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.detail_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.edit_action){
            goToForm();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        Intent intent = new Intent(this, ProjectOverviewActivity.class);
        startActivity(intent);
    }

    private void goToForm() {
        Intent intent = new Intent(this, ProjectFormActivity.class);
        intent.putExtra(EXTRA_PROJECT, project);
        startActivity(intent);
    }

    private void updateUI() {
        getSupportFragmentManager().beginTransaction().replace(R.id.taskList_fragment_container_details, TaskListFragment.newInstance(project)).commit();
        if (project.getTasks() == null || project.getTasks().isEmpty()){
            ArrayList<Task> tasks = new ArrayList<>();
            ArrayList<String> taskIds = new ArrayList<>();
            project.setTasks(tasks);
            project.setTaskIds(taskIds);
        }
        projectTitle.setText(project.getTitle());
        NumberFormat numberFormat = NumberFormat.getCurrencyInstance(Locale.US);
        String currency = numberFormat.format(project.getBudget());
        projectBudget.setText(currency);
        updateImageIcon();
    }

    private void updateImageIcon() {
        switch (project.getCategory()){
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
    public void addTaskToFirestore(Task task) {
        DocumentReference newTaskRef = db.collection("tasks").document();
        newTaskRef.set(task).addOnSuccessListener(aVoid -> {
            String newTaskId = newTaskRef.getId();
            task.setTaskId(newTaskId);
            Log.d(TAG, "Task successfully added with ID: " + newTaskId);
            project.getTasks().add(task);
            project.getTaskIds().add(newTaskId);

            // Update the task in Firestore
            newTaskRef.set(task);

            // Update the project in Firestore
            DocumentReference projectRef = db.collection("projects").document(project.getProjectID());
            projectRef.set(project);
        }).addOnFailureListener(e -> Log.d(TAG, "Error adding task", e));
    }

    @Override
    public void deleteTasksFromFirestore(ArrayList<Task> tasks) {
        WriteBatch batch = db.batch();

        for (Task task : tasks) {
            // Remove task from Firestore
            DocumentReference taskRef = db.collection("tasks").document(task.getTaskId());
            batch.delete(taskRef);

            // Remove task from the project's tasks and taskIds
            project.getTasks().remove(task);
            project.getTaskIds().remove(task.getTaskId());
        }

        // Update the project in Firestore
        DocumentReference projectRef = db.collection("projects").document(project.getProjectID());
        batch.set(projectRef, project);

        batch.commit().addOnSuccessListener(aVoid -> Log.d(TAG, "Tasks successfully deleted")).addOnFailureListener(e -> Log.d(TAG, "Error deleting tasks", e));
    }
}
