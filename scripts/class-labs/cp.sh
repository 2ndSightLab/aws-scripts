echo "Commit Message"
read msg

if [ -z "$msg" ]; then
  echo "must enter a commit message!"
  exit
fi

echo "Enter lab folder to copy"
read folder

if [ -z "$folder" ]; then
  echo "must enter a folder!"
  exit
fi

echo "Enter classcode (e.g., beta, lds..)"
read classcode


if [ -z "$classcode" ]; then
  echo "must enter a class code!"
  exit
fi

echo "update github..."
git add .
git commit -m "$msg"
git push

echo "update bitbucket https://tradichel@2ndSightLab@bitbucket.org/2sl3000/cls-2sl3000-$classcode.git"

cd ..
rm -rf "cls-2sl3000-$classcode/"
git clone https://2ndSightLab@bitbucket.org/2sl3000/cls-2sl3000-$classcode.git

cp -r "2SL3000-Lab-Content/$folder" "cls-2sl3000-$classcode"
cd "cls-2sl3000-$classcode"

git add .
git commit -m "$msg"
git push

cd "../2SL3000-Lab-Content"
