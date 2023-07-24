package com.example.hallmorgan_renoready_android;

import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.text.InputType;
import android.util.Log;
import android.util.Pair;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;

import com.bumptech.glide.Glide;
import com.example.hallmorgan_renoready_android.helperClasses.HelperMethods;
import com.example.hallmorgan_renoready_android.helperClasses.PermissionsHelper;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.EmailAuthProvider;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.QueryDocumentSnapshot;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;

import java.io.IOException;
import java.util.ArrayList;

@SuppressWarnings("unchecked")
public class ProfileActivity extends AppCompatActivity implements View.OnClickListener {

    private static final String TAG = "ProfileActivity";

    private ImageView profilePicture;
    private TextView email_label;
    private final FirebaseAuth mAuth = FirebaseAuth.getInstance();
    private FirebaseUser currentUser;
    private final FirebaseFirestore db = FirebaseFirestore.getInstance();
    private final FirebaseStorage storage = FirebaseStorage.getInstance();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);

        currentUser = mAuth.getCurrentUser();

        profilePicture = findViewById(R.id.profilePic_profileScreen);
        email_label = findViewById(R.id.userEmail_profile);
        setProfilePicture();
        profilePicture.setOnClickListener(this);
        findViewById(R.id.changeEmail_button).setOnClickListener(this);
        findViewById(R.id.changePassword_button).setOnClickListener(this);
        findViewById(R.id.logout_button).setOnClickListener(this);
        findViewById(R.id.deleteAccount_button).setOnClickListener(this);

        updateEmail();

    }

    private void setProfilePicture() {
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        String uid = user.getUid();
        StorageReference profileRef = FirebaseStorage.getInstance().getReference().child(uid + "/profile_images/profile_photo.jpg");

        profileRef.getDownloadUrl().addOnSuccessListener(new OnSuccessListener<Uri>() {
            @Override
            public void onSuccess(Uri uri) {
                // Got the download URL
                Glide.with(ProfileActivity.this)
                        .load(uri)
                        .into(profilePicture);
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception exception) {
                // Handle any errors
                Log.e("Firebase", "Error downloading image", exception);
            }
        });


    }

    private void updateEmail() {
        if (currentUser != null){
            email_label.setText(currentUser.getEmail());
        }
    }

    @Override
    public void onClick(View view) {
        if (view.getId() == R.id.profilePic_profileScreen){
            // Array of options to display in the dialog
            String[] options = {"Take Photo", "Choose from Gallery"};

            // Create the dialog
            AlertDialog.Builder builder = new AlertDialog.Builder(view.getContext());
            builder.setTitle("Choose Profile Photo");
            builder.setItems(options, (dialogInterface, i) -> {
                // Handle the selected option
                switch (i) {
                    case 0: // Take Photo
                        PermissionsHelper.checkCameraPermissions(ProfileActivity.this);
                        break;

                    case 1: // Choose from Gallery
                        PermissionsHelper.checkStoragePermissions(ProfileActivity.this);
                        break;
                }
            });
            builder.show();
        } else if (view.getId() == R.id.changeEmail_button){
            changeEmail(view);

        } else if (view.getId() == R.id.changePassword_button){
            changePassword(view);

        } else if (view.getId() == R.id.logout_button){
           logout();

        } else if (view.getId() == R.id.deleteAccount_button){
            // Delete user's associated data
            // Assume 'db' is your Firestore instance
            db.collection("projects").whereEqualTo("userId", currentUser.getUid())
                    .get()
                    .addOnCompleteListener(task -> {
                        if (task.isSuccessful()) {
                            for (QueryDocumentSnapshot document : task.getResult()) {
                                // Assume 'tasks' is the array of tasks IDs in the project
                                ArrayList<String> tasks = (ArrayList<String>) document.get("tasks");
                                if (tasks != null) {
                                    for (String taskId : tasks) {
                                        db.collection("tasks").document(taskId).delete();
                                    }
                                }
                                // Delete the project document itself
                                document.getReference().delete();
                            }
                            // Delete user's profile picture in storage
                            // Assume 'storage' is your Firebase Storage instance
                            // And 'profilePicturePath' is the path to the user's profile picture
                            String profilePicturePath = "profilePictures/" + currentUser.getUid();
                            StorageReference profilePicRef = storage.getReference().child(profilePicturePath);
                            profilePicRef.delete();

                            // Delete the user account
                            currentUser.delete()
                                    .addOnCompleteListener(task12 -> {
                                        if (task12.isSuccessful()) {
                                            Log.d(TAG, "User account deleted.");
                                            // Log the user out and clear all activities from the stack
                                           logout();
                                        } else {
                                            Log.d(TAG, "Failed to delete user account.", task12.getException());
                                        }
                                    });
                        } else {
                            Log.d(TAG, "Failed to get projects.", task.getException());
                        }
                    });
        }
    }

    private void logout(){
        // Log the user out
        mAuth.signOut();
        // Clear all activities from the stack
        Intent intent = new Intent(ProfileActivity.this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    private void changePassword(View view) {
        AlertDialog.Builder builder = new AlertDialog.Builder(view.getContext());
        builder.setTitle("Change Password");

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);

        final EditText currentPasswordInput = new EditText(view.getContext());
        currentPasswordInput.setHint("Current Password");
        currentPasswordInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        layout.addView(currentPasswordInput);

        final EditText newPasswordInput = new EditText(view.getContext());
        newPasswordInput.setHint("New Password");
        newPasswordInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        layout.addView(newPasswordInput);

        builder.setView(layout);

        builder.setPositiveButton("OK", (dialog, id) -> {
            String currentPassword = currentPasswordInput.getText().toString();
            String newPassword = newPasswordInput.getText().toString();

            Pair<Boolean, String> passwordCheck = HelperMethods.isValidPassword(newPassword);

            if (!passwordCheck.first) {
                Toast.makeText(ProfileActivity.this, "Invalid new password", Toast.LENGTH_SHORT).show();
                return;
            }

            // re-authenticate user
            if (currentUser != null && currentUser.getEmail() != null) {
                AuthCredential credential = EmailAuthProvider
                        .getCredential(currentUser.getEmail(), currentPassword);

                currentUser.reauthenticate(credential)
                        .addOnCompleteListener(task -> {
                            if (task.isSuccessful()) {
                                currentUser.updatePassword(newPassword)
                                        .addOnCompleteListener(task1 -> {
                                            if (task1.isSuccessful()) {
                                                Log.d(TAG, "User password updated.");
                                                Toast.makeText(ProfileActivity.this, "Password successfully updated", Toast.LENGTH_SHORT).show();
                                            } else {
                                                Log.d(TAG, "Error password not updated");
                                                Toast.makeText(ProfileActivity.this, "Failed to update password", Toast.LENGTH_SHORT).show();
                                            }
                                        });
                            } else {
                                Log.d(TAG, "Error auth failed");
                                Toast.makeText(ProfileActivity.this, "Current password was incorrect. Please try again", Toast.LENGTH_SHORT).show();
                            }
                        });
            }
        });

        builder.setNegativeButton("Cancel", (dialog, id) -> {
            // User cancelled the dialog
        });

        builder.show();
    }

    private void changeEmail(View view) {
        AlertDialog.Builder builder = new AlertDialog.Builder(view.getContext());
        builder.setTitle("Change Email");

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);

        final EditText currentEmailInput = new EditText(view.getContext());
        currentEmailInput.setHint("Current Email");
        layout.addView(currentEmailInput);

        final EditText newEmailInput = new EditText(view.getContext());
        newEmailInput.setHint("New Email");
        layout.addView(newEmailInput);

        final EditText passwordInput = new EditText(view.getContext());
        passwordInput.setHint("Password");
        passwordInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        layout.addView(passwordInput);

        builder.setView(layout);

        builder.setPositiveButton("OK", (dialog, id) -> {
            String currentEmail = currentEmailInput.getText().toString();
            String newEmail = newEmailInput.getText().toString();
            String password = passwordInput.getText().toString();

            if (currentUser != null && currentUser.getEmail() != null && currentUser.getEmail().equals(currentEmail)) {
                if (HelperMethods.isValidEmail(newEmail)) {
                    // Re-authenticate user
                    AuthCredential credential = EmailAuthProvider.getCredential(currentEmail, password);
                    currentUser.reauthenticate(credential)
                            .addOnCompleteListener(task -> {
                                if (task.isSuccessful()) {
                                    currentUser.updateEmail(newEmail)
                                            .addOnCompleteListener(task1 -> {
                                                if (task1.isSuccessful()) {
                                                    Log.d(TAG, "User email address updated.");
                                                    Toast.makeText(ProfileActivity.this, "Email successfully updated", Toast.LENGTH_SHORT).show();
                                                    updateEmail();
                                                } else {
                                                    Log.d(TAG, "Error email not updated");
                                                    Toast.makeText(ProfileActivity.this, "Failed to update email", Toast.LENGTH_SHORT).show();
                                                }
                                            });
                                } else {
                                    Log.d(TAG, "Error auth failed");
                                    Toast.makeText(ProfileActivity.this, "Failed to authenticate. Incorrect email or password.", Toast.LENGTH_SHORT).show();
                                }
                            });
                } else {
                    Toast.makeText(ProfileActivity.this, "Invalid new email", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(ProfileActivity.this, "Current email does not match.", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setNegativeButton("Cancel", (dialog, id) -> {
            // User cancelled the dialog
        });

        builder.show();
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
                profilePicture.setImageBitmap(roundedBitmap);
            } else {
                // Use the default image from the drawable resources
                Drawable defaultProfilePicture = ContextCompat.getDrawable(this, R.drawable.defaultprofilepic);
                profilePicture.setImageDrawable(defaultProfilePicture);
            }
        }
    }
}
