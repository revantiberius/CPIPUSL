# CPIPUSL
Cloudflare Policy IPv4 and IPv6 IP Update Script 4 Linux

I wrote these as a way to allow my cell phone to access my cloudflare Zero trust sites, as mTLS is not an option in Cloudflare for policies without Enterprise licensing.  Between a DDNS application on my phone that updates the DNS and these scripts I'm able to access my sites without issue.  That being said, there is a delay between DNS updates and the script running.

These are two scripts I wrote for updating IP bypass policies in Cloudflare.  One script updates only ipv4 and the other updates both IPv4 and IPv6.  The create 12 line rotating log files in $HOME.  They also include the cron info for setting them up to run every 5 minutes.
