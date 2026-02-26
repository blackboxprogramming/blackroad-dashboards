<?php
/**
 * Plugin Name: BlackRoad Dashboards
 * Plugin URI: https://github.com/blackboxprogramming/blackroad-dashboards
 * Description: Embed beautiful terminal-style dashboards into your WordPress site with shortcodes
 * Version: 1.0.0
 * Author: BlackBox Programming
 * Author URI: https://github.com/blackboxprogramming
 * License: MIT
 * Text Domain: blackroad-dashboards
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

class BlackRoad_Dashboards {
    
    private $version = '1.0.0';
    
    public function __construct() {
        add_action('wp_enqueue_scripts', array($this, 'enqueue_assets'));
        add_shortcode('blackroad_dashboard', array($this, 'render_dashboard'));
        add_action('admin_menu', array($this, 'add_admin_menu'));
    }
    
    public function enqueue_assets() {
        wp_enqueue_style(
            'blackroad-dashboards',
            plugins_url('assets/css/dashboard-core.css', __FILE__),
            array(),
            $this->version
        );
        
        wp_enqueue_script(
            'blackroad-core',
            plugins_url('assets/js/dashboard-core.js', __FILE__),
            array(),
            $this->version,
            true
        );
    }
    
    public function render_dashboard($atts) {
        $atts = shortcode_atts(array(
            'type' => 'system',
            'refresh' => '5000',
            'theme' => 'dark',
            'controls' => 'true',
            'height' => 'auto',
        ), $atts);
        
        $dashboard_id = 'blackroad-' . uniqid();
        $dashboard_class = $this->get_dashboard_class($atts['type']);
        
        // Enqueue specific dashboard script
        wp_enqueue_script(
            'blackroad-' . $atts['type'],
            plugins_url('assets/js/dashboards/' . $atts['type'] . '-dashboard.js', __FILE__),
            array('blackroad-core'),
            $this->version,
            true
        );
        
        $output = '<div id="' . esc_attr($dashboard_id) . '" class="blackroad-dashboard-container"';
        if ($atts['height'] !== 'auto') {
            $output .= ' style="height: ' . esc_attr($atts['height']) . '"';
        }
        $output .= '></div>';
        
        $output .= '<script>
            jQuery(document).ready(function($) {
                new ' . esc_js($dashboard_class) . '("' . esc_js($dashboard_id) . '", {
                    refreshInterval: ' . intval($atts['refresh']) . ',
                    theme: "' . esc_js($atts['theme']) . '",
                    showControls: ' . ($atts['controls'] === 'true' ? 'true' : 'false') . '
                }).start();
            });
        </script>';
        
        return $output;
    }
    
    private function get_dashboard_class($type) {
        $dashboards = array(
            'system' => 'SystemDashboard',
            'kubernetes' => 'KubernetesDashboard',
            'docker' => 'DockerDashboard',
            'postgresql' => 'PostgreSQLDashboard',
            'mongodb' => 'MongoDBDashboard',
            'redis' => 'RedisDashboard',
            'api' => 'APIDashboard',
            'security' => 'SecurityDashboard',
            'iot' => 'IoTDashboard',
            'crypto' => 'CryptoDashboard',
        );
        
        return isset($dashboards[$type]) ? $dashboards[$type] : 'SystemDashboard';
    }
    
    public function add_admin_menu() {
        add_menu_page(
            'BlackRoad Dashboards',
            'Dashboards',
            'manage_options',
            'blackroad-dashboards',
            array($this, 'admin_page'),
            'dashicons-chart-area',
            30
        );
    }
    
    public function admin_page() {
        ?>
        <div class="wrap">
            <h1>BlackRoad Dashboards</h1>
            <p>Embed beautiful dashboards into your WordPress site using shortcodes.</p>
            
            <h2>Available Shortcodes</h2>
            
            <div class="notice notice-info">
                <p><strong>Quick Start:</strong> Copy any shortcode below and paste it into your post or page!</p>
            </div>
            
            <table class="wp-list-table widefat fixed striped">
                <thead>
                    <tr>
                        <th>Dashboard Type</th>
                        <th>Shortcode</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>System Monitor</td>
                        <td><code>[blackroad_dashboard type="system"]</code></td>
                        <td>CPU, Memory, Disk, Network monitoring</td>
                    </tr>
                    <tr>
                        <td>Kubernetes</td>
                        <td><code>[blackroad_dashboard type="kubernetes"]</code></td>
                        <td>Kubernetes cluster monitoring</td>
                    </tr>
                    <tr>
                        <td>Docker</td>
                        <td><code>[blackroad_dashboard type="docker"]</code></td>
                        <td>Docker container monitoring</td>
                    </tr>
                    <tr>
                        <td>API Monitor</td>
                        <td><code>[blackroad_dashboard type="api"]</code></td>
                        <td>API endpoint health monitoring</td>
                    </tr>
                    <tr>
                        <td>Security</td>
                        <td><code>[blackroad_dashboard type="security"]</code></td>
                        <td>Security alerts and monitoring</td>
                    </tr>
                    <tr>
                        <td>IoT Devices</td>
                        <td><code>[blackroad_dashboard type="iot"]</code></td>
                        <td>IoT device monitoring</td>
                    </tr>
                    <tr>
                        <td>Crypto Portfolio</td>
                        <td><code>[blackroad_dashboard type="crypto"]</code></td>
                        <td>Cryptocurrency portfolio tracking</td>
                    </tr>
                </tbody>
            </table>
            
            <h2>Shortcode Parameters</h2>
            <table class="wp-list-table widefat fixed striped">
                <thead>
                    <tr>
                        <th>Parameter</th>
                        <th>Default</th>
                        <th>Options</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><code>type</code></td>
                        <td>system</td>
                        <td>system, kubernetes, docker, etc.</td>
                        <td>Type of dashboard to display</td>
                    </tr>
                    <tr>
                        <td><code>refresh</code></td>
                        <td>5000</td>
                        <td>Any number (milliseconds)</td>
                        <td>Auto-refresh interval (0 = no auto-refresh)</td>
                    </tr>
                    <tr>
                        <td><code>theme</code></td>
                        <td>dark</td>
                        <td>dark, light, terminal</td>
                        <td>Visual theme</td>
                    </tr>
                    <tr>
                        <td><code>controls</code></td>
                        <td>true</td>
                        <td>true, false</td>
                        <td>Show control buttons</td>
                    </tr>
                    <tr>
                        <td><code>height</code></td>
                        <td>auto</td>
                        <td>Any CSS height value</td>
                        <td>Container height (e.g., 600px)</td>
                    </tr>
                </tbody>
            </table>
            
            <h2>Example Usage</h2>
            <pre><code>[blackroad_dashboard type="system" refresh="3000" theme="dark" controls="true" height="600px"]</code></pre>
        </div>
        <?php
    }
}

// Initialize plugin
new BlackRoad_Dashboards();
