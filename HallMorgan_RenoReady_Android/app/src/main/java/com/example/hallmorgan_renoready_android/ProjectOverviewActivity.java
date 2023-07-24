package com.example.hallmorgan_renoready_android;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import com.example.hallmorgan_renoready_android.fragments.ProjectListFragment;
import com.example.hallmorgan_renoready_android.objects.Project;
import com.google.firebase.firestore.FirebaseFirestore;

import java.util.ArrayList;

public class ProjectOverviewActivity extends AppCompatActivity implements ProjectListFragment.ProjectsListener {
    private static final String TAG = "ProjectOverviewActivity";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        // Set the navigation icon and its click listener
        toolbar.setNavigationIcon(R.drawable.profile_icon);
        toolbar.setNavigationOnClickListener(view -> {
            // Handle the profile icon click
            // Replace this with the logic you previously had in onOptionsItemSelected()
            Intent profileIntent = new Intent(this, ProfileActivity.class);
            startActivity(profileIntent);
        });



        findViewById(R.id.create_newProject_button).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent newProjectIntent = new Intent(ProjectOverviewActivity.this, ProjectFormActivity.class);
                startActivity(newProjectIntent);
                finish();
            }
        });

        getSupportFragmentManager().beginTransaction().replace(R.id.list_fragment_container, ProjectListFragment.newInstance()).commit();


    }

    @Override
    public void openProjectDetails(Project project) {
        Intent projectDetailsIntent = new Intent(this, ProjectDetailsActivity.class);
        projectDetailsIntent.putExtra(ProjectDetailsActivity.EXTRA_PROJECT, project);
        startActivity(projectDetailsIntent);
    }

    @Override
    public void deleteProject(ArrayList<Project> projects) {
        FirebaseFirestore db = FirebaseFirestore.getInstance();
        for (Project project : projects){
            // Delete tasks
            ArrayList<String> taskIDs = project.getTaskIds();
            if (taskIDs != null && !taskIDs.isEmpty()) {
                for (String taskID : taskIDs) {
                    db.collection("tasks").document(taskID).delete().addOnSuccessListener(unused -> Log.d(TAG, "Task: " + taskID + " successfully deleted from firestore")).addOnFailureListener(e -> Log.d(TAG, "Error deleting task: " + taskID));
                }
            }

            // Delete the project
            db.collection("projects").document(project.getProjectID()).delete().addOnSuccessListener(unused -> Log.d(TAG, "Project: " + project.getTitle() + " successfully deleted from firestore")).addOnFailureListener(e -> Log.d(TAG, "Error deleting project: " + project.getTitle()));
        }
    }
}
