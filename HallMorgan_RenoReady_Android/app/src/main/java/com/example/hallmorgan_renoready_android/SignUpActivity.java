package com.example.hallmorgan_renoready_android;

import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.util.Pair;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;

import com.example.hallmorgan_renoready_android.helperClasses.HelperMethods;
import com.example.hallmorgan_renoready_android.helperClasses.PermissionsHelper;
import com.example.hallmorgan_renoready_android.objects.User;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SignUpActivity extends AppCompatActivity {
    private static final String TAG = "SignUpActivity";

    private FirebaseAuth auth;
    private FirebaseFirestore db;
    private FirebaseStorage storage;

    private LinearLayout progressOverlay;

    private ImageView profileImage;

    private EditText email_editText;
    private EditText password_editText;
    private EditText confirmPass_editText;

    Button signUp_button;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sign_up);

        auth = FirebaseAuth.getInstance();
        storage = FirebaseStorage.getInstance();
        db = FirebaseFirestore.getInstance();

        profileImage = findViewById(R.id.profilePic_signUp);
        email_editText = findViewById(R.id.newEmail_editText);
        password_editText = findViewById(R.id.newPassword_editText);
        confirmPass_editText = findViewById(R.id.confirmPassword_editText);
        signUp_button = findViewById(R.id.newUser_signUp_button);

        //Set touch target on profile picture
        profileImage.setOnClickListener(view -> {
            // Array of options to display in the dialog
            String[] options = {"Take Photo", "Choose from Gallery"};

            // Create the dialog
            AlertDialog.Builder builder = new AlertDialog.Builder(view.getContext());
            builder.setTitle("Choose Profile Photo");
            builder.setItems(options, (dialogInterface, i) -> {
                // Handle the selected option
                switch (i) {
                    case 0: // Take Photo
                        PermissionsHelper.checkCameraPermissions(SignUpActivity.this);
                        break;

                    case 1: // Choose from Gallery
                        PermissionsHelper.checkStoragePermissions(SignUpActivity.this);
                        break;
                }
            });
            builder.show();
        });

        signUp_button.setOnClickListener(view -> signUpTapped());

        progressOverlay = findViewById(R.id.progressOverlay);

    }

    private void signUpTapped() {
        showLoadingView();
        List<String> errorMessages = new ArrayList<>();

        // Check that the email is valid
        String email = email_editText.getText().toString();

        if (!HelperMethods.isValidEmail(email)) {
            errorMessages.add("The email address entered is not a valid email");
        }

        // Check that the password is valid
        String password = password_editText.getText().toString();

        Pair<Boolean, String> passwordCheck = HelperMethods.isValidPassword(password);
        if (!passwordCheck.first) {
            errorMessages.add("Password must contain " + passwordCheck.second);
        }

        // Check that the password is confirmed
        String confirmedPass = confirmPass_editText.getText().toString();
        if (!confirmedPass.equals(password)) {
            errorMessages.add("Password entries do not match");
        }

        // If there are any errors, show them in an alert
        if (!errorMessages.isEmpty()) {
            hideLoadingView();
            HelperMethods.showBasicErrorAlert(this, "Sign Up Failed", String.join("\n", errorMessages));
        } else {
            //Create the user with firebase
            createUser(email, password);
        }

    }

    private void createUser(String email, String password) {
        auth.createUserWithEmailAndPassword(email, password).addOnCompleteListener(this, task -> {
            if (task.isSuccessful()){
                FirebaseUser firebaseUser = auth.getCurrentUser();
                if(firebaseUser != null){
                    String uid = firebaseUser.getUid();
                    Drawable profileDrawable = ResourcesCompat.getDrawable(getResources(), R.drawable.defaultprofilepic, null);
                    Bitmap bitmap;
                    if (profileDrawable instanceof BitmapDrawable) {
                        bitmap = ((BitmapDrawable) profileDrawable).getBitmap();
                        User user = new User(email, bitmap);
                        //Add user to firestore
                        addUserToFirestore(uid, user, () -> {
                            hideLoadingView();
                            goToHomeScreen();
                        });
                    }
                }
            }
        });
    }

    private void goToHomeScreen() {
        Intent goToHomeIntent = new Intent(this, ProjectOverviewActivity.class);
        startActivity(goToHomeIntent);
    }

    private void addUserToFirestore(String uid, User user, Runnable completion) {
        StorageReference userPhotosRef = storage.getReference().child(uid + "/profile_images/profile_photo.jpg");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        user.getProfilePhoto().compress(Bitmap.CompressFormat.JPEG, 75, baos);
        byte[] data = baos.toByteArray();

        UploadTask uploadTask = userPhotosRef.putBytes(data);

        uploadTask.addOnFailureListener(exception -> HelperMethods.showBasicErrorAlert(SignUpActivity.this, "Error", exception.getMessage())).addOnSuccessListener(taskSnapshot -> userPhotosRef.getDownloadUrl().addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                Uri downloadUrl = task.getResult();

                Map<String, Object> userData = new HashMap<>();
                userData.put("email", user.getEmail());
                userData.put("profile_photo_url", downloadUrl.toString());
                userData.put("projects", new ArrayList<String>());

                db.collection("users").document(uid).set(userData).addOnCompleteListener(dbTask -> {
                    if (dbTask.isSuccessful()) {
                        completion.run();
                        Log.i(TAG, "User was successfully added to firestore");
                    } else {
                        if (dbTask.getException() != null) {
                            hideLoadingView();
                            HelperMethods.showBasicErrorAlert(this, "Error", "Error adding user to Firestore: " + dbTask.getException().getLocalizedMessage());
                        }
                    }
                });
            } else {
                if (task.getException() != null) {
                    hideLoadingView();
                    HelperMethods.showBasicErrorAlert(this, "Error", "Error getting download URL: " + task.getException().getLocalizedMessage());

                }
            }
        }));
    }



    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK) {
            Bitmap bitmap = null;
            if (requestCode == PermissionsHelper.CAMERA_CAPTURE_REQUEST_CODE) {
                // If the result comes from the camera
                if (data != null) {
                    bitmap = (Bitmap) data.getExtras().get("data");
                }
            } else if (requestCode == PermissionsHelper.STORAGE_PERMISSION_REQUEST_CODE) {
                // If the result comes from the gallery
                try {
                    Uri selectedImage;
                    if (data != null) {
                        selectedImage = data.getData();
                        bitmap = MediaStore.Images.Media.getBitmap(this.getContentResolver(), selectedImage);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                    return;
                }
            }

            if (bitmap != null) {
                // Apply round bitmap function and set the image to the ImageView
                Bitmap roundedBitmap = PermissionsHelper.getRoundedBitmap(bitmap);
                profileImage.setImageBitmap(roundedBitmap);
            } else {
                // Use the default image from the drawable resources
                Drawable defaultProfilePicture = ContextCompat.getDrawable(this, R.drawable.defaultprofilepic);
                profileImage.setImageDrawable(defaultProfilePicture);
            }
        }
    }

    private void showLoadingView() {
        progressOverlay.setVisibility(View.VISIBLE);
    }

    private void hideLoadingView() {
        progressOverlay.setVisibility(View.GONE);
    }
}
