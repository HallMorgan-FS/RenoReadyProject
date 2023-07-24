package com.example.hallmorgan_renoready_android.helperClasses;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.core.content.res.ResourcesCompat;

import com.example.hallmorgan_renoready_android.R;
import com.example.hallmorgan_renoready_android.objects.Project;

import java.util.ArrayList;

public class ProjectListBaseAdapter extends BaseAdapter {

    //Base ID
    private static final long Base_ID = 0x1011;

    //Reference to our owning screen (context)
    private final Context context;

    private final ArrayList<Project> projects;

    public ProjectListBaseAdapter(Context _context, ArrayList<Project> _projects){
        context = _context;
        projects = _projects;
    }

    @Override
    public int getCount() {
        if (projects != null){
            return projects.size();
        }
        return 0;
    }

    @Override
    public Object getItem(int position) {
        if (projects != null && position < projects.size()){
            return projects.get(position);
        }
        return null;
    }

    @Override
    public long getItemId(int i) {
        return Base_ID + i;
    }

    @Override
    public View getView(int position, View view, ViewGroup viewGroup) {
        ViewHolder vh;
        Project project = projects.get(position);

        if (view == null){
            view = LayoutInflater.from(context).inflate(R.layout.project_list_layout, viewGroup, false);
            vh = new ViewHolder(view);
            view.setTag(vh);
        } else {
            vh = (ViewHolder) view.getTag();
        }

        if (project != null){
            vh.project_title.setText(project.getTitle());
            String category = project.getCategory();
            switch (category){
                case "KITCHEN":
                    vh.categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(context.getResources(),R.drawable.kitchen, null));
                    break;
                case "LIVING ROOM":
                    vh.categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(context.getResources(),R.drawable.livingroom, null));
                    break;
                case "Bathroom":
                    vh.categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(context.getResources(),R.drawable.bathroom, null));
                    break;
                case "BEDROOM":
                    vh.categoryIcon.setImageDrawable(ResourcesCompat.getDrawable(context.getResources(),R.drawable.bedroom, null));
                    break;
            }
        }

        return view;
    }

    static class ViewHolder{
        final ImageView categoryIcon;
        final TextView project_title;

        public ViewHolder(View _layout){
            categoryIcon = _layout.findViewById(R.id.project_list_category_icon);
            project_title = _layout.findViewById(R.id.project_list_title);
        }
    }
}
