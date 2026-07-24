@echo off
echo Activating virtual environment...
call .venv\Scripts\activate

echo Running Scraper...
cd scraper
python scraper.py
cd ..

echo Pushing to GitHub...
git add .
git commit -m "Auto-update TV guide from local machine"
git push

echo Done!