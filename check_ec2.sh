ec2 scan save && clear

email="osama9mohamed5@gmail.com"
inst_path="$HOME/running_instances.txt"
running_inst=$(grep running ~/.aws/regions/scan | awk '{print $2 " - " $7}' | sort | uniq -c | sed 's/,//g') # print running instances types and names
date=$(date +%F) # print date without time and seconds and time zone

echo -e "$date:\n$running_inst\n----------------------------------------" >> $inst_path
cat $inst_path

# ----------------------👇 This function installs and configures ssmtp if triggered 👇---------------------- #
instal_smtp(){
    # ------First install ssmtp------ #
    sudo apt-get install ssmtp
    # ------Then lets configure it by editing the ssmtp.conf file with values from input prompt------ #
    read -p "Please enter your gmail account ex.(user@gmail.com): " root 
    AuthUser=$(echo $root | sed 's/@gmail.com//g')
    # ---------------------- How to generate gmail app pass ---------------- #
    echo -e """\nTo get 'AuthPass' value do the following:
    1. open your google account settings then tab on security
    2. then scroll down to 'Signing in to Google' here you'll do the following: \n\t a. enable 2-Step Verification. \n\t b. create app pass. \n\nHere's a couple of documentations that explains it: \n\t * https://support.google.com/mail/answer/185833?hl=en \n\t * https://devanswers.co/create-application-specific-password-gmail/\n"""
    # ---------------------------------------------------------------------------- #
    read -p "Please enter the (AuthPass) new password you've just created: " AuthPass && echo
    if [ -z "$AuthPass" ]; then
        echo "Error: AuthPass is empty" >&2 && echo
        exit 1
    fi
# ----------------- 👇 configure smtp 👇 ----------------- #
    cat <<EOF > /etc/ssmtp/ssmtp.conf
root=$root
mailhub=smtp.gmail.com:465
rewriteDomain=gmail.com
AuthUser=$AuthUser
AuthPass=$AuthPass
FromLineOverride=YES
UseTLS=YES
EOF
# ----------------- 👆 configure smtp 👆 ----------------- #
    # ------install dependencies------ #
    apt-get install libio-socket-ssl-perl libnet-ssleay-perl sendemail mailutils
}
# ----------------------👆 This function installs and configures ssmtp if triggered 👆---------------------- #

# check if $running_inst has "large" or "xlarge" in it and if it does, then send an email to $email
# if echo "$running_inst" | grep -q "large" || echo "$running_inst" | grep -q "xlarge"; then

echo "Sending email to $email"
# ------------------------ check if ssmtp is installed ----------------------- #
if ! [ -x "$(command -v ssmtp)" ]; then
    echo "Error: ssmtp is not installed." >&2 && echo
    instal_smtp
fi
# -------------------- check if ~/.aws/regions/scan exists ------------------- #
if ! [ -f ~/.aws/regions/scan ]; then
    echo "Error: ~/.aws/regions/scan does not exist." >&2 && echo
    echo -e 'Please run:\nec2 scan save'
    exit 1
fi
# --------------------------------- send mail -------------------------------- #
echo -e "The following AWS instance are currently running:\n\n$(cat $inst_path)" | mail -s "Warning large/xlarge instances" $email
rm mail.txt
# ------------------------------- or with ssmtp ------------------------------ #
# echo -e "Subject: Warning large/xlarge instances\n\nThe following AWS instance are currently running:\n\n$(cat $inst_path)" | ssmtp $email

# fi

