package com.example.hallmorgan_renoready_android.objects;

import com.google.firebase.firestore.DocumentSnapshot;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

@SuppressWarnings({"unchecked", "ConstantConditions"})
public class Project implements Serializable {
    private String projectID;
    private String title;
    private String category;
    private double budget;
    private ArrayList<Task> tasks;
    private ArrayList<String> taskIds;

    public Project(){

    }

    public Project(String projectID, String title, String category, double budget, ArrayList<Task> tasks, ArrayList<String> taskIds) {
        this.projectID = projectID;
        this.title = title;
        this.category = category;
        this.budget = budget;
        this.tasks = tasks = new ArrayList<>();
        this.taskIds = taskIds = new ArrayList<>();
    }


    public Project(String projectID, String title, String category,
                   double budget) {
        this(projectID, title, category, budget, null, null);
    }

    // Add Getters and Setters
    public String getProjectID() {
        return projectID;
    }

    public void setProjectID(String projectID) {
        this.projectID = projectID;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public double getBudget() {
        return budget;
    }

    public void setBudget(double budget) {
        this.budget = budget;
    }

    public ArrayList<Task> getTasks() {
        return tasks;
    }

    public void setTasks(ArrayList<Task> tasks) {
        this.tasks = tasks;
    }

    public ArrayList<String> getTaskIds() {
        return taskIds;
    }

    public void setTaskIds(ArrayList<String> taskIds) {
        this.taskIds = taskIds;
    }

    public static Project from(DocumentSnapshot document) {
        String projectID = document.getString("projectID");
        String title = document.getString("title");
        String category = document.getString("category");
        Double budget = document.getDouble("budget");
        ArrayList<Task> tasks = (ArrayList<Task>) document.get("tasks");
        ArrayList<String> taskIds = (ArrayList<String>) document.get("taskIds");

        // if tasks or taskIds are null, initialize them to empty ArrayLists
        if (tasks == null) {
            tasks = new ArrayList<>();
        }

        if (taskIds == null) {
            taskIds = new ArrayList<>();
        }

        return new Project(projectID, title, category, budget, tasks, taskIds);
    }


    public Map<String, Object> toDictionary() {
        Map<String, Object> dictionary = new HashMap<>();
        dictionary.put("projectID", this.projectID);
        dictionary.put("title", this.title);
        dictionary.put("category", this.category);
        dictionary.put("budget", this.budget);

        // Only add these properties to the dictionary if they're not null
        if (this.taskIds != null) {
            dictionary.put("tasks", this.taskIds);
        }

        return dictionary;
    }
}
