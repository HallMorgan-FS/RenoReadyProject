package com.example.hallmorgan_renoready_android.objects;

import androidx.annotation.NonNull;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

public class Task implements Serializable {
    private String taskId;
    private String task;

    public Task(){

    }

    public Task(String taskId, String task) {
        this.taskId = taskId;
        this.task = task;
    }
    //Add Getters and Setters
    public String getTaskId(){
        return taskId;
    }

    public void setTaskId(String id){
        this.taskId = id;
    }

    public String getTask() {return task;}

    public void setTask(String title) {this.task = title;}

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null || getClass() != obj.getClass()) return false;

        Task task = (Task) obj;

        return taskId.equals(task.taskId);
    }

    @Override
    public int hashCode() {
        return taskId.hashCode();
    }

    @NonNull
    @Override
    public String toString() {
        return task;
    }
}
