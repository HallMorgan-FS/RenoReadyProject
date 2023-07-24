package com.example.hallmorgan_renoready_android.helperClasses;

import android.app.Activity;
import android.app.AlertDialog;
import android.util.Pair;
import android.widget.EditText;

import java.util.regex.Pattern;

public class HelperMethods {

    public static void showBasicErrorAlert(Activity activity, String title, String message){
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle(title);
        builder.setMessage(message + "\nWe apologize for this inconvenience.");
        builder.setPositiveButton("OK", (dialog, which) -> dialog.dismiss());
        AlertDialog alertDialog = builder.create();
        alertDialog.show();
    }

    public static boolean isValidEmail(String email) {
        String regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}";
        return Pattern.matches(regex, email);
    }

    public static Pair<Boolean, String> isValidPassword(String password) {
        // Check that password is at least 8 characters long
        if (password.length() < 8) {
            return new Pair<>(false, "at least 8 characters");
        }

        // Check that password contains at least one uppercase letter
        if (!Pattern.matches(".*[A-Z]+.*", password)) {
            return new Pair<>(false, "one uppercase letter");
        }

        // Check that password contains at least one number
        if (!Pattern.matches(".*[0-9]+.*", password)) {
            return new Pair<>(false, "at least one number");
        }

        // If all checks passed, return true
        return new Pair<>(true, "Passed");
    }

    public static Pair<Boolean, String> textNotEmpty(EditText textField) {
        //Check that edit text field is not empty
        String text = textField.getText().toString().trim();
        if (text.isEmpty()) {
            return new Pair<>(false, "Empty or whitespace");
        }
        return new Pair<>(true, text);
    }

}
