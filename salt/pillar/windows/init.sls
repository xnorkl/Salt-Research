# Define the file download parameters
git_file_download:
  source_path: azurefs:// # This prefix tells Salt to use the Azure fileserver backend
  destination_path: /tmp/downloads  # Where to save the file on the minion
  filename: file.txt  # The name of your file in Azure blob storage 
