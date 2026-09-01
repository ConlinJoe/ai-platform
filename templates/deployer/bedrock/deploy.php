<?php

declare(strict_types=1);

namespace Deployer;

/**
 * AI Development Harness Deployer stack.
 * Profile: bedrock
 *
 * AI_PLATFORM_DEPLOYER_STACK=bedrock
 *
 * Installing or configuring this file does not authorize deployment.
 * Host, repository, and SSH values live in deploy/hosts.yaml.
 */

require 'recipe/composer.php';

$hosts = __DIR__ . '/deploy/hosts.yaml';
if (!is_file($hosts)) {
    fwrite(STDERR, "Missing deploy/hosts.yaml. Copy deploy/hosts.yaml.example and fill in server values.\n");
    fwrite(STDERR, "Configuring hosts does not authorize deployment.\n");
    exit(1);
}

import($hosts);

set('keep_releases', 5);
set('git_tty', false);
set('public_path', 'web');
set('shared_files', ['.env']);
set('shared_dirs', ['web/app/uploads']);
set('writable_dirs', ['web/app/uploads']);

// Document root is web/. Point the web server at current/web.
// Shared environment and uploads survive across releases.
// This recipe does not run database imports, search-replace, or
// provision tasks.

desc('Deploy Bedrock WordPress');
task('deploy', [
    'deploy:prepare',
    'deploy:vendors',
    'deploy:publish',
]);
