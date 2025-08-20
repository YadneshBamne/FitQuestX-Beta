package com.codeforany.fitness

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import com.codeforany.fitness.R

class HomeWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        // Dummy data for illustration
        val bmi = 23.4f
        val bmiText = "BMI: $bmi"
        val category = "Normal Weight"
        val tip = "💡 Great job! Keep maintaining your healthy lifestyle"
        val updatedTime = "Last updated: ${getCurrentTime()}"

        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // Update text fields
        views.setTextViewText(R.id.bmiValueText, bmiText)
        views.setTextViewText(R.id.categoryText, "Category: $category")
        views.setTextViewText(R.id.healthTipText, tip)
        views.setTextViewText(R.id.lastUpdatedText, updatedTime)

        // Set category text color
        val categoryColorRes = getCategoryColor(bmi)
        views.setTextColor(R.id.categoryText, ContextCompat.getColor(context, categoryColorRes))

        // Optional: set icon if needed (check if image resource is compatible)
        views.setImageViewResource(R.id.bmiIcon, R.drawable.ic_health)
        views.setImageViewResource(R.id.refreshButton, R.drawable.ic_refresh)

        // Apply widget updates
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getCurrentTime(): String {
        val sdf = java.text.SimpleDateFormat("MMM dd, HH:mm", java.util.Locale.getDefault())
        return sdf.format(java.util.Date())
    }

    private fun getCategoryColor(bmi: Float): Int {
        return when {
            bmi < 18.5 -> android.R.color.holo_blue_light
            bmi < 25 -> android.R.color.holo_green_light
            bmi < 30 -> android.R.color.holo_orange_light
            else -> android.R.color.holo_red_light
        }
    }
}
