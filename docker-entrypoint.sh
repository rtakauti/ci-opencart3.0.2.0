#!/bin/bash
set -euo pipefail

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		case "$1" in
			apache2*)
				user="${APACHE_RUN_USER:-www-data}"
				group="${APACHE_RUN_GROUP:-www-data}"
				;;
			*) # php-fpm
				user='www-data'
				group='www-data'
				;;
		esac
	else
		user="$(id -u)"
		group="$(id -g)"
	fi

	if ! [ -e index.php -a -e admin/config.php ]; then
		echo >&2 "Opencart not found in $PWD - copying now..."
		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi
		tar --create \
			--file - \
			--one-file-system \
			--directory /usr/src/opencart \
			--owner "$user" --group "$group" \
			. | tar --extract --file -
		echo >&2 "Complete! Opencart has been successfully copied to $PWD"
		if [ ! -e .htaccess ]; then
			# NOTE: The "Indexes" option is disabled in the php:apache base image
			cat > .htaccess <<-'EOF'
				# BEGIN Opencart
				Options +FollowSymlinks
				Options -Indexes

				<FilesMatch "(?i)((\.tpl|.twig|\.ini|\.log|(?<!robots)\.txt))">
				 Require all denied
				</FilesMatch>

				RewriteEngine On
				RewriteBase /
				RewriteRule ^sitemap.xml$ index.php?route=extension/feed/google_sitemap [L]
				RewriteRule ^googlebase.xml$ index.php?route=extension/feed/google_base [L]
				RewriteRule ^system/storage/(.*) index.php?route=error/not_found [L]
				RewriteCond %{REQUEST_FILENAME} !-f
				RewriteCond %{REQUEST_FILENAME} !-d
				RewriteCond %{REQUEST_URI} !.*\.(ico|gif|jpg|jpeg|png|js|css)
				RewriteRule ^([^?]*) index.php?_route_=$1 [L,QSA]
				# END Opencart
			EOF
			chown "$user:$group" .htaccess
		fi
	fi

fi

exec "$@"
