<?php 
/**
 * Simple script for Mailcatcher testing.
 */

ini_set( 'display_errors', 1 );
error_reporting( E_ALL );

mail(
    "info@dogstido.be",
    "PHP Mail Test script",
    "This is a test to check the PHP Mail functionality", 
    "From:info@dogstudio.be" 
);

echo "Done.";
