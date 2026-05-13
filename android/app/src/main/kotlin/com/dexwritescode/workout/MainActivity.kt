package com.dexwritescode.workout

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.ui.unit.dp
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.dexwritescode.workout.ui.theme.AppColors
import com.dexwritescode.workout.ui.theme.WorkoutTheme
import com.dexwritescode.workout.ui.workout.WorkoutNavGraph

private sealed class Tab(val route: String, val label: String, val icon: ImageVector) {
    object Workout   : Tab("workout",   "Workout",   Icons.Default.FitnessCenter)
    object Recovery  : Tab("recovery",  "Recovery",  Icons.Default.SelfImprovement)
    object History   : Tab("history",   "History",   Icons.Default.History)
    object Exercises : Tab("exercises", "Exercises", Icons.Default.BarChart)
    object Settings  : Tab("settings",  "Settings",  Icons.Default.Person)
}

private val tabs = listOf(Tab.Workout, Tab.Recovery, Tab.History, Tab.Exercises, Tab.Settings)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            WorkoutTheme {
                AppShell()
            }
        }
    }
}

@Composable
private fun AppShell() {
    val rootNav = rememberNavController()
    val navBackStack by rootNav.currentBackStackEntryAsState()
    val currentDestination = navBackStack?.destination

    Scaffold(
        containerColor = AppColors.background,
        bottomBar = {
            NavigationBar(containerColor = AppColors.surface1, tonalElevation = 0.dp) {
                tabs.forEach { tab ->
                    val selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true
                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            rootNav.navigate(tab.route) {
                                popUpTo(rootNav.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label, fontSize = 10.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = AppColors.brand,
                            selectedTextColor = AppColors.brand,
                            unselectedIconColor = AppColors.textTertiary,
                            unselectedTextColor = AppColors.textTertiary,
                            indicatorColor = AppColors.brand.copy(alpha = 0.12f),
                        ),
                    )
                }
            }
        },
    ) { innerPadding ->
        val context = LocalContext.current
        NavHost(
            navController = rootNav,
            startDestination = Tab.Workout.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Tab.Workout.route) {
                val workoutNav = rememberNavController()
                WorkoutNavGraph(navController = workoutNav, context = context)
            }
            composable(Tab.Recovery.route) { PlaceholderTab("Recovery") }
            composable(Tab.History.route) { PlaceholderTab("History") }
            composable(Tab.Exercises.route) { PlaceholderTab("Exercises") }
            composable(Tab.Settings.route) { PlaceholderTab("Settings") }
        }
    }
}

@Composable
private fun PlaceholderTab(name: String) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(name, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = AppColors.textTertiary)
    }
}
