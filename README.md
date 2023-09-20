# RenoReady: The Ultimate Renovation Companion

### Description

RenoReady is a mobile application designed to assist users in planning and executing home renovation projects. The app provides a comprehensive platform to manage tasks, budgets, and timelines for various renovation activities.

This application is still under development and was created as a final project. Updates are still being made and a release in the app store is being planned.

### Key Features

- Project Management: Create and manage multiple renovation projects.
- Task Tracking: Add, update, and track tasks related to each project.
- Budget Estimation: Calculate and manage your budget.
- Timeline: Set and monitor project deadlines.
- Repository holding the developing stages of the RenoReady application. Including the alpha version for IOS and Android, along with the Beta version for IOS

### Technologies Used

- iOS: Swift, Xcode
- Android: Java, Android Studio
- Backend: Firebase
- Version Control: Git

### Installation and Setup
1. **Close the Repository**
   
   ```
   git clone https://github.com/HallMorgan-FS/RenoReadyProject.git
   ```
2. **iOS Setup**
  - Open HallMorgan_RenoReady.xcodeproj in Xcode.
  - Install the required packages.
  - Build and run the project.
3. **Android Setup**
  - Open the Android project in Android Studio.
  - Sync Gradle and install required dependencies.
  - Build and run the project.

### Usage

- **iOS:** Navigate through the app using the tab bar at the bottom.
- **Android**: Use the navigation drawer to switch between different sections.

### Code Examples

- **Adding a New Task (iOS - swift)**

  ```
  static func addTaskToProject(projectID: String, taskId: String, completion: @escaping (Error?) -> Void){
        let projectsCollection = Firestore.firestore().collection("projects")
        
        // Use FieldValue.arrayUnion to add the taskId to the tasks array field
        // arrayUnion will only add the taskId if it's not already present in the array
        projectsCollection.document(projectID).updateData([
            "tasks": FieldValue.arrayUnion([taskId])
        ]) { error in
            completion(error)
        }
    }
  ```

- **Fetching Projects (Android - java)**
   
  ```
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
  ```

### Contribution Guidelines

We welcome contributions to improve the app. Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature.
3. Submit a pull request for review.

### License

This project is licensed under the MIT License - see the LICENSE.md file for details.

### Contact Information

For any queries or contributions, please contact:

- **Email: morganhall.dev@outlook.com**

### Screenshots

**(Left to Right) Sign Up Screen, Project Detail Screen, Project Overview Screen**

![RenoReady Screens](https://github.com/HallMorgan-FS/RenoReadyProject/assets/77134790/f030ea14-4090-4fb2-aaf3-5f456b2a6cd0)

  
