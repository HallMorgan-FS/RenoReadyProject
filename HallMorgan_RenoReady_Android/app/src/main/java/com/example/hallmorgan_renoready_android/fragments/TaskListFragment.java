package com.example.hallmorgan_renoready_android.fragments;

import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.text.InputType;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.ListFragment;

import com.example.hallmorgan_renoready_android.R;
import com.example.hallmorgan_renoready_android.objects.Project;
import com.example.hallmorgan_renoready_android.objects.Task;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;

import java.util.ArrayList;

public class TaskListFragment extends Fragment {
    private static final String TAG = "TaskListFragment";
    public static final String ARGS_PROJECT = "com.example.hallmorgan_renoready_android.fragments.ARGS_PROJECT";

    private LinearLayout add_remove_layout;
    private LinearLayout delete_cancel_layout;
    private ListView listView;
    private TextView noTasksTextView;
    private Button removeTask;
    private ArrayAdapter<Task> adapter;


    private ArrayList<Task> tasks = new ArrayList<>();
    private ArrayList<Task> selectedTasks;

    boolean isInEditMode = false;

    TaskListener mListener;

    public interface TaskListener {
        void addTaskToFirestore(Task task);
        void deleteTasksFromFirestore(ArrayList<Task> tasks);
    }

    public static TaskListFragment newInstance(Project project) {
        Bundle args = new Bundle();
        args.putSerializable(ARGS_PROJECT, project);
        TaskListFragment fragment = new TaskListFragment();
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof TaskListener){
            mListener = (TaskListener) context;
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_task_list, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        View root = getView();
        if (root != null){
            listView = root.findViewById(R.id.tasks_list);
            add_remove_layout = root.findViewById(R.id.add_remove_layout);
            delete_cancel_layout = root.findViewById(R.id.delete_cancel_layout);
            Button addTask = root.findViewById(R.id.addTaskButton);
            removeTask = root.findViewById(R.id.removeTaskButton);
            Button deleteTask = root.findViewById(R.id.deleteTaskButton);
            Button cancelButton = root.findViewById(R.id.cancel_delete_button);
            noTasksTextView = root.findViewById(R.id.no_tasks_view);
            selectedTasks = new ArrayList<>();

            listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
                @Override
                public void onItemClick(AdapterView<?> adapterView, View v, int position, long l) {
                    if (isInEditMode){
                        //Toggle task selection
                        Task task = tasks.get(position);
                        if (selectedTasks.contains(task)){
                            selectedTasks.remove(task);
                            v.setBackgroundColor(Color.TRANSPARENT);
                        } else {
                            selectedTasks.add(task);
                            v.setBackgroundColor(Color.LTGRAY);
                        }
                    }
                }
            });

            Bundle args = getArguments();
            if (args != null){
                Project project = (Project) args.getSerializable(ARGS_PROJECT);
                if (project != null && project.getTaskIds() != null){
                    getTasks(project.getTaskIds());
                }
            }

            addTask.setOnClickListener(view14 -> showAddTaskAlert());

            removeTask.setOnClickListener(view13 -> {
                add_remove_layout.setVisibility(View.GONE);
                isInEditMode = true;
                delete_cancel_layout.setVisibility(View.VISIBLE);
            });

            deleteTask.setOnClickListener(view12 -> {
                if (mListener != null) {
                    mListener.deleteTasksFromFirestore(selectedTasks);
                    tasks.removeAll(selectedTasks);
                }
                isInEditMode = false;
                delete_cancel_layout.setVisibility(View.GONE);
                add_remove_layout.setVisibility(View.VISIBLE);
                listView.clearChoices();
                updateUI();
            });

            cancelButton.setOnClickListener(view1 -> {
                isInEditMode = false;
                delete_cancel_layout.setVisibility(View.GONE);
                add_remove_layout.setVisibility(View.VISIBLE);
                listView.clearChoices();
            });

        }

    }

    private void showAddTaskAlert() {
        Context context = getContext();
        if (context != null){
            AlertDialog.Builder builder = new AlertDialog.Builder(getContext());
            builder.setTitle("Add New Task");
            final EditText input = new EditText(getContext());
            input.setHint(R.string.add_task_hint);
            input.setInputType(InputType.TYPE_CLASS_TEXT);
            builder.setView(input);
            builder.setPositiveButton("Add Task", (dialog, which) -> {
                String title = input.getText().toString();
                Task task = new Task("", title);  // Assuming your Task object takes a title as a constructor
                tasks.add(task);
                if (mListener != null) {
                    mListener.addTaskToFirestore(task);
                }

                updateUI();

            });
            builder.setNegativeButton("Cancel", (dialog, which) -> dialog.cancel());
            builder.show();
        }

    }

    private void getTasks(ArrayList<String> taskIds){
        FirebaseFirestore db = FirebaseFirestore.getInstance();
        tasks = new ArrayList<>();

        for (String taskId : taskIds) {
            DocumentReference taskRef = db.collection("tasks").document(taskId);
            taskRef.get().addOnCompleteListener(_task -> {
                if (_task.isSuccessful()){
                    DocumentSnapshot taskDocument = _task.getResult();
                    if (taskDocument.exists()){
                        Task task = taskDocument.toObject(Task.class);
                        if (task != null){
                            //Add tasks to the array
                            tasks.add(task);
                            updateUI();
                        }
                    } else {
                        Log.d(TAG, "onComplete: No such task");
                    }
                } else {
                    if (_task.getException() != null){
                        Log.d(TAG, "onComplete: get failed with ", _task.getException());
                    }
                }
            });
        }
    }

    private void updateUI(){
        if(tasks.isEmpty()){
            noTasksTextView.setVisibility(View.VISIBLE);
            listView.setVisibility(View.GONE);
            add_remove_layout.setVisibility(View.VISIBLE);
            removeTask.setVisibility(View.GONE);
        } else {
            noTasksTextView.setVisibility(View.GONE);
            listView.setVisibility(View.VISIBLE);
            add_remove_layout.setVisibility(View.VISIBLE);
            removeTask.setVisibility(View.VISIBLE);
            if (adapter == null) {
                adapter = new ArrayAdapter<>(getActivity(), android.R.layout.simple_list_item_1, tasks);
                listView.setAdapter(adapter);
            } else {
                adapter.notifyDataSetChanged();
            }
        }
    }
}
