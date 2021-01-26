package com.example.snailmap.ui.home;

import android.Manifest;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProviders;

import com.example.snailmap.MainActivity;
import com.example.snailmap.R;
import com.example.snailmap.ui.ImageClassifier.ImageClassifier;
import com.example.snailmap.ui.LocationTrack.LocationTrack;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FirebaseFirestore;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import static android.Manifest.permission.ACCESS_COARSE_LOCATION;
import static android.Manifest.permission.ACCESS_FINE_LOCATION;

public class HomeFragment extends Fragment {
    //CAMERA_PERMISSION_REQUEST_CODE & CAMERA_REQUEST_CODE & ALL_PERMISSIONS_RESULT
    private static final int CAMERA_PERMISSION_REQUEST_CODE = 1000;
    private static final int CAMERA_REQUEST_CODE = 1001;
    private final static int ALL_PERMISSIONS_RESULT = 101;

    //ArrayList for permissions
    private ArrayList permissionsToRequest;
    private ArrayList permissionsRejected = new ArrayList();
    private ArrayList permissions = new ArrayList();

    //define locationTrack
    LocationTrack locationTrack;

    //define longitude and latitude
    double longitude;
    double latitude;

    //define if the image has snail
    boolean haveSnail;

    //define imageClassifier
    private ImageClassifier imageClassifier;

    //imageView and textView on Home Page
    private ImageView imageView;
    private TextView numOfSnails;
    private TextView coordinates;

    //button for use camera
    Button camera;

    //onCreateView for home page fragment
    public View onCreateView(@NonNull LayoutInflater inflater,
                             ViewGroup container, Bundle savedInstanceState) {
        final View root = inflater.inflate(R.layout.fragment_home, container, false);
        imageView = (ImageView) root.findViewById(R.id.imageView2);
        numOfSnails = (TextView) root.findViewById(R.id.textView1);
        coordinates = (TextView) root.findViewById(R.id.textView2);
        camera = (Button) root.findViewById(R.id.button);

        //ask permissions for location
        permissions.add(ACCESS_FINE_LOCATION);
        permissions.add(ACCESS_COARSE_LOCATION);
        permissionsToRequest = findUnAskedPermissions(permissions);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (permissionsToRequest.size() > 0)
                requestPermissions((String[]) permissionsToRequest.toArray(new String[permissionsToRequest.size()]), ALL_PERMISSIONS_RESULT);
        }

        //try to load imageClassifier
        try {
            imageClassifier = new ImageClassifier(getActivity());
        } catch (IOException e) {
            Log.e("Image Classifier Error", "ERROR: " + e);
        }

        //camera listener
        camera.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                locationTrack = new LocationTrack(getContext());

                if (locationTrack.canGetLocation()) {
                    longitude = locationTrack.getLongitude();
                    latitude = locationTrack.getLatitude();
                } else {

                    locationTrack.showSettingsAlert();
                }
                // checking whether camera permissions are available.
                // if permission is avaialble then we open camera intent to get picture
                // otherwise requests for permissions
                if (hasPermission()) {
                    openCamera();
                } else {
                    requestPermission();
                }
            }
        });
        return root;
    }

    private ArrayList findUnAskedPermissions(ArrayList wanted) {
        ArrayList result = new ArrayList();
        for (Object perm : wanted) {
            if (!hasPermission((String) perm)) {
                result.add(perm);
            }
        }
        return result;
    }

    private boolean hasPermission(String permission) {
        if (canMakeSmores()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                return (ActivityCompat.checkSelfPermission(getContext(),permission) == PackageManager.PERMISSION_GRANTED);
            }
        }
        return true;
    }

    private boolean canMakeSmores() {
        return (Build.VERSION.SDK_INT > Build.VERSION_CODES.LOLLIPOP_MR1);
    }

    //function of reset count of snails
    private void resetcount() {
        int numofsnail = 0;
    }

    //deal the captured image
    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        // if this is the result of our camera image request
        if (requestCode == CAMERA_REQUEST_CODE && resultCode == getActivity().RESULT_OK) {

            // getting bitmap of the image
            Bitmap photo = (Bitmap) data.getExtras().get("data");
            // displaying this bitmap in imageview
            imageView.setImageBitmap(photo);
            int countsnail = 0;
            // pass this bitmap to classifier to make prediction
            List<ImageClassifier.Recognition> predictions = imageClassifier.recognizeImage(
                    photo, 0);
            // creating a list of string to display in list view
            for (ImageClassifier.Recognition recog : predictions) {
                if (recog.getName() == "snail") {
                    countsnail += 1;
                }
            }
            //set haveSnail by count of snails
            if (countsnail >= 1) {
                haveSnail = true;
            } else {
                haveSnail = false;
            }
            //set text view
            coordinates.setText("Latitude: " + latitude + "\n Longitude: " + longitude +"\n Number of Snail: " + countsnail);
            //save data to could if the data is right
            if (longitude != 0.0 && latitude != 0.0) {
                FirebaseFirestore db = FirebaseFirestore.getInstance();
                Map<String, Object> snaildetection = new HashMap<>();
                snaildetection.put("longitude", longitude);
                snaildetection.put("latitude", latitude);
                snaildetection.put("NumberofSnails", countsnail);
                snaildetection.put("HaveSnail", haveSnail);
                snaildetection.put("DateTime", new Date());

                db.collection("snail-detection")
                        .add(snaildetection)
                        .addOnSuccessListener(new OnSuccessListener<DocumentReference>() {
                            @Override
                            public void onSuccess(DocumentReference documentReference) {
                                Log.d("TAG", "DocumentSnapshot added with ID: " + documentReference.getId());
                            }
                        })
                        .addOnFailureListener(new OnFailureListener() {
                            @Override
                            public void onFailure(@NonNull Exception e) {
                                Log.w("TAG", "Error adding document", e);
                            }
                        });
            }
            super.onActivityResult(requestCode, resultCode, data);
        }
    }
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (hasAllPermissions(grantResults)) {
                openCamera();
            } else {
                requestPermission();
            }
        }
        switch (requestCode) {
            case ALL_PERMISSIONS_RESULT:
                for (Object perms : permissionsToRequest) {
                    if (!hasPermission((String) perms)) {
                        permissionsRejected.add(perms);
                    }
                }
                if (permissionsRejected.size() > 0) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (shouldShowRequestPermissionRationale((String) permissionsRejected.get(0))) {
                            showMessageOKCancel("These permissions are mandatory for the application. Please allow access.",
                                    new DialogInterface.OnClickListener() {
                                        @Override
                                        public void onClick(DialogInterface dialog, int which) {
                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                                requestPermissions((String[]) permissionsRejected.toArray(new String[permissionsRejected.size()]), ALL_PERMISSIONS_RESULT);
                                            }
                                        }
                                    });
                            return;
                        }
                    }
                }
                break;
        }
    }
    //function for show message to ask user allow the Permissions
    private void showMessageOKCancel (String message, DialogInterface.OnClickListener
            okListener){
        new AlertDialog.Builder(getActivity())
                .setMessage(message)
                .setPositiveButton("OK", okListener)
                .setNegativeButton("Cancel", null)
                .create()
                .show();
    }

    //if has hasAllPermissions return true, otherWise return false
    private boolean hasAllPermissions ( int[] grantResults){
        for (int result : grantResults) {
            if (result == PackageManager.PERMISSION_DENIED)
                return false;
        }
        return true;
    }


    /**
     * Method requests for permission if the android version is marshmallow or above
     */
    private void requestPermission () {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // whether permission can be requested or on not
            if (shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)) {
                Toast.makeText(getActivity(), "Camera Permission Required", Toast.LENGTH_SHORT).show();
            }
            // request the camera permission permission
            requestPermissions(new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST_CODE);

        }
    }

    /**
     * creates and starts an intent to get a picture from camera
     */
    private void openCamera () {
        try {
            Intent cameraIntent = new Intent();
            cameraIntent.setAction(MediaStore.ACTION_IMAGE_CAPTURE);
            startActivityForResult(cameraIntent,CAMERA_REQUEST_CODE);

        }catch (Exception e){
            e.printStackTrace();
        }
    }

    /**
     * checks whether camera permission is available or not
     *
     * @return true if android version is less than marshmallo,
     * otherwise returns whether camera permission has been granted or not
     */
    private boolean hasPermission () {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return ActivityCompat.checkSelfPermission(getContext(),Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }
}