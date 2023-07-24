package com.example.hallmorgan_renoready_android.fragments;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.hallmorgan_renoready_android.MainActivity;
import com.example.hallmorgan_renoready_android.R;
import com.example.hallmorgan_renoready_android.helperClasses.HelperMethods;
import com.example.hallmorgan_renoready_android.helperClasses.ProjectListBaseAdapter;
import com.example.hallmorgan_renoready_android.objects.Project;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;

import java.util.ArrayList;
import java.util.concurrent.CountDownLatch;

@SuppressWarnings("unchecked")
public class ProjectListFragment extends Fragment {
    private static final String TAG = "ProjectListFragment";

    private TextView numProjects;
    private Button editButton;
    private ListView listView;
    private TextView noProjectsView;

    private ArrayList<Project> projects;
    private ArrayList<Project> selectedProjects;

    ProjectsListener mListener;

    public interface ProjectsListener {
        void openProjectDetails(Project project);
        void deleteProject(ArrayList<Project> projects);
    }

    private boolean isEditingMode = false;

    public static ProjectListFragment newInstance() {

        Bundle args = new Bundle();

        ProjectListFragment fragment = new ProjectListFragment();
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof ProjectsListener){
            mListener = (ProjectsListener) context;
        }
    }

    @Override
    public void onCreateOptionsMenu(@NonNull Menu menu, @NonNull MenuInflater inflater) {
        inflater.inflate(R.menu.list_editing_menu, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.action_delete){
            onDeleteMenuItemClicked();
        }
        return super.onOptionsItemSelected(item);
    }

    private void onDeleteMenuItemClicked() {
        if (isEditingMode && !selectedProjects.isEmpty()){
            if (mListener != null){
                mListener.deleteProject(selectedProjects);
            }
            projects.removeAll(selectedProjects);
            selectedProjects.clear();
            updateUI();
            ((ProjectListBaseAdapter)listView.getAdapter()).notifyDataSetChanged();
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_project_list, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setHasOptionsMenu(true);
        View root = getView();
        if (root != null){
            numProjects = root.findViewById(R.id.numProjects_label);
            editButton = root.findViewById(R.id.list_edit_button);
            listView = root.findViewById(R.id.project_listView);
            noProjectsView = root.findViewById(R.id.no_projects_view);

            getAllProjects();

            selectedProjects = new ArrayList<>();

            ProjectListBaseAdapter adapter = new ProjectListBaseAdapter(getActivity(), projects);
            listView.setAdapter(adapter);

            //List item click listener
            listView.setOnItemClickListener((adapterView, view12, position, id) -> {
                if (isEditingMode){
                    Project project = projects.get(position);
                    if (selectedProjects.contains(project)){
                        selectedProjects.remove(project);
                        view12.setBackgroundColor(Color.TRANSPARENT);
                    } else {
                        selectedProjects.add(project);
                        view12.setBackgroundColor(Color.LTGRAY);
                    }
                } else {
                    if (mListener != null){
                        mListener.openProjectDetails(projects.get(position));
                    }
                }
            });

            //Edit button click listener
            editButton.setOnClickListener(view1 -> {
                isEditingMode = !isEditingMode;
                if (isEditingMode){
                    editButton.setText(R.string.done);
                    requireActivity().invalidateOptionsMenu();
                } else {
                    editButton.setText(R.string.edit);
                    requireActivity().invalidateOptionsMenu();
                }
            });

        }
    }

    @Override
    public void onPrepareOptionsMenu(@NonNull Menu menu) {
        super.onPrepareOptionsMenu(menu);
        MenuItem deleteItem = menu.findItem(R.id.action_delete);
        deleteItem.setVisible(isEditingMode);
    }

    private void getAllProjects(){
        projects = new ArrayList<>();
        String userID = "";
        //Get UID of current user
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user != null){
            userID = user.getUid();
        } else {
            HelperMethods.showBasicErrorAlert(getActivity(), "Error", "There is currently no user. Please sign back in.");
            Intent intent = new Intent(getActivity(), MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(intent);
            if (getActivity() != null){
                getActivity().finish();
            }
        }

        FirebaseFirestore db = FirebaseFirestore.getInstance();

        // Fetch user's data from Firestore
        DocumentReference userRef = db.collection("users").document(userID);
        userRef.get().addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                DocumentSnapshot document = task.getResult();
                if (document.exists()) {
                    // Retrieve the list of project IDs
                    ArrayList<String> projectIds = (ArrayList<String>) document.get("projects");

                    if (projectIds != null) {
                        if (projectIds.isEmpty()){
                            // Show the noProjectsView
                            noProjectsView.setVisibility(View.VISIBLE);
                            listView.setVisibility(View.GONE);
                            updateUI();
                        } else {
                            // Fetch each project using its ID
                            for (String projectId : projectIds) {
                                DocumentReference projectRef = db.collection("projects").document(projectId);
                                projectRef.get().addOnCompleteListener(task1 -> {
                                    if (task1.isSuccessful()) {
                                        DocumentSnapshot projectDocument = task1.getResult();
                                        if (projectDocument.exists()) {
                                            // Deserialize the project document to a Project object
                                            Project project = projectDocument.toObject(Project.class);
                                            // Add to projects array
                                            projects.add(project);

                                            if (getActivity() != null) {
                                                getActivity().runOnUiThread(() -> {
                                                    listView.setVisibility(View.VISIBLE);
                                                    noProjectsView.setVisibility(View.GONE);
                                                    // Update UI
                                                    updateUI();
                                                    // Notify the adapter
                                                    ((ProjectListBaseAdapter) listView.getAdapter()).notifyDataSetChanged();
                                                });
                                            }
                                        } else {
                                            Log.d(TAG, "No such project");
                                        }
                                    } else {
                                        Log.d(TAG, "get failed with ", task1.getException());
                                    }
                                });
                            }
                        }
                    }
                } else {
                    Log.d(TAG, "No such user");
                }
            } else {
                Log.d(TAG, "get failed with ", task.getException());
            }
        });
    }

    private void updateUI(){
        @NonNull
        String projectSize = getString(R.string.numProjects, projects.size());
        numProjects.setText(projectSize);
    }
}
