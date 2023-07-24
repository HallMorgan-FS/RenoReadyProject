package com.example.hallmorgan_renoready_android;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.text.InputType;
import android.util.Pair;
import android.widget.Button;
import android.widget.EditText;

import com.example.hallmorgan_renoready_android.helperClasses.HelperMethods;
import com.example.hallmorgan_renoready_android.helperClasses.PermissionsHelper;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;


public class MainActivity extends AppCompatActivity {

    EditText email_editText;
    EditText password_editText;
    Button forgotPass_button;
    Button signIn_button;
    Button signUp_button;

    String userEmail;
    String userPassword;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        if(getSupportActionBar() != null) {
            getSupportActionBar().hide();
        }
        email_editText = findViewById(R.id.email_editText);
        password_editText = findViewById(R.id.password_editText);

        //Check network
        if (PermissionsHelper.isNetworkConnected(this)){
            //Device is connected to the internet, continue with login
            checkForLoggedInUser();
        } else {
            //No internet connection
            HelperMethods.showBasicErrorAlert(this, "No Internet", "This application requires the device to be connected to the internet in order to best serve it's purpose. Please connect to the internet and try again.");
        }

    }

    private void checkForLoggedInUser(){
        FirebaseAuth firebaseAuth = FirebaseAuth.getInstance();
        FirebaseUser currentUser = firebaseAuth.getCurrentUser();
        if (currentUser != null){
            //Continue to the home screen
            goToHomeScreen();
        } else {
            //User is not logged in, proceed with login
            setButtonActions();
        }
    }

    private void setButtonActions() {
        forgotPass_button = findViewById(R.id.forgotPass_button);
        signUp_button = findViewById(R.id.signUp_button);
        signIn_button = findViewById(R.id.signIn_button);
        forgotPass_button.setOnClickListener(view -> forgotPasswordTapped());

        signIn_button.setOnClickListener(view -> signInTapped());

        signUp_button.setOnClickListener(view -> {
            Intent signUpIntent = new Intent(MainActivity.this, SignUpActivity.class);
            startActivity(signUpIntent);
        });
    }

    private void goToHomeScreen(){
        Intent signInIntent = new Intent(MainActivity.this, ProjectOverviewActivity.class);
        startActivity(signInIntent);
    }

    private void signInTapped() {
        // Verify the user input
        Pair<Boolean, String> emailCheck = HelperMethods.textNotEmpty(email_editText);
        Pair<Boolean, String> passwordCheck = HelperMethods.textNotEmpty(password_editText);

        if (emailCheck.first && passwordCheck.first) {
            userEmail = emailCheck.second;
            userPassword = passwordCheck.second;

            // Sign in via Firebase Auth
            signInWithFirebase();

        } else {
            // Send alert
            HelperMethods.showBasicErrorAlert(this, "Error", "Email and password fields cannot be left blank. Please try again.");

        }
    }

    private void signInWithFirebase() {
        FirebaseAuth.getInstance().signInWithEmailAndPassword(userEmail, userPassword)
                .addOnCompleteListener(this, task -> {
                    if (task.isSuccessful()) {
                        // If successful, navigate to the next activity
                        goToHomeScreen();
                    } else {
                        if (task.getException() != null) {
                            HelperMethods.showBasicErrorAlert(MainActivity.this, "Error", task.getException().getLocalizedMessage() + "\nPlease try again.");
                        }
                    }
                });
    }

    private void forgotPasswordTapped() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Reset Password");
        builder.setMessage("Please enter your email address:");

        // Set up the input
        final EditText input = new EditText(this);
        input.setInputType(InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
        input.setHint("johndoe@email.com");
        builder.setView(input);

        // Set up the buttons
        builder.setPositiveButton("Send", (dialog, which) -> {
            String emailToBeReset = input.getText().toString();
            FirebaseAuth.getInstance().sendPasswordResetEmail(emailToBeReset)
                    .addOnCompleteListener(task -> {
                        if (task.isSuccessful()) {
                            HelperMethods.showBasicErrorAlert(MainActivity.this, "Success", "A reset password link has been sent to your email if the email address is registered to a user.");
                        } else {
                            if (task.getException() != null){
                                HelperMethods.showBasicErrorAlert(MainActivity.this, "Error", task.getException().getLocalizedMessage() + "\nPlease try again.");
                            }
                        }
                    });
        });
        builder.setNegativeButton("Cancel", null);

        builder.show();
    }
}