package com.example.hallmorgan_renoready_android.objects;

import android.graphics.Bitmap;

import java.io.Serializable;
import java.util.ArrayList;

public class User implements Serializable {
    private String email;
    private Bitmap profilePhoto;
    private ArrayList<Project> projects;

    public User(){

    }

    public User(String email, Bitmap profilePhoto, ArrayList<Project> projects){
        this.email = email;
        this.profilePhoto = profilePhoto;
        this.projects = projects;
    }

    public User(String email, Bitmap profilePhoto) {
        this.email = email;
        this.profilePhoto = profilePhoto;
        this.projects = null;
    }

    // Getter and Setter methods
    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Bitmap getProfilePhoto() {
        return profilePhoto;
    }

    public void setProfilePhoto(Bitmap profilePhoto) {
        this.profilePhoto = profilePhoto;
    }

    public ArrayList<Project> getProjects(){
        return projects;
    }

    public void setProjects(ArrayList<Project> projects){
        this.projects = projects;
    }


}
