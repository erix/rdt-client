using Serilog;

namespace RdtClient.Service.Services.Downloaders;

public class SymlinkDownloader : IDownloader
{
    public event EventHandler<DownloadCompleteEventArgs>? DownloadComplete;
    public event EventHandler<DownloadProgressEventArgs>? DownloadProgress;

    private readonly String _filePath;
    private readonly String _uri;
    
    private readonly CancellationTokenSource _cancellationToken = new();
    
    private readonly ILogger _logger;
    
    public SymlinkDownloader(String uri, String filePath)
    {
        _logger = Log.ForContext<SymlinkDownloader>();

        _uri = uri;
        _filePath = filePath;
    }

    public Task<String?> Download()
    {
        _logger.Debug($"Starting symlink resolving of {_uri}, writing to path: {_filePath}");

        var fileName = Path.GetFileName(_filePath);
        var fileExtension = Path.GetExtension(_filePath).ToLower();

        // Check if the file is a .rat or .zip file for special handling.
        if (fileExtension == ".rar" || fileExtension == ".zip")
        {
            var targetFolderName = Path.GetFileNameWithoutExtension(_filePath);
            _logger.Debug($"Searching {Settings.Get.DownloadClient.RcloneMountPath} for folder {targetFolderName}");

            var foundFolders = Directory.GetDirectories(Settings.Get.DownloadClient.RcloneMountPath, targetFolderName, SearchOption.AllDirectories);

            if (foundFolders.Any())
            {
                if (foundFolders.Length > 1)
                {
                    _logger.Warning($"Found {foundFolders.Length} folders named {targetFolderName}");
                }

                var actualFolderPath = foundFolders.First();
                var filesInFolder = Directory.GetFiles(actualFolderPath);

                foreach (var file in filesInFolder)
                {
                    var targetFileName = Path.GetFileName(file);
                    var symlinkTargetPath = Path.Combine(_filePath, targetFileName);
                    TryCreateSymbolicLink(file, symlinkTargetPath);
                }

                DownloadComplete?.Invoke(this, new DownloadCompleteEventArgs());
                _logger.Information($"Folder {targetFolderName} found on {Settings.Get.DownloadClient.RcloneMountPath} at {actualFolderPath}");
                return Task.FromResult<String?>(actualFolderPath);
            }
        }
        else
        {
            // Original code logic for handling single file.
            _logger.Debug($"Searching {Settings.Get.DownloadClient.RcloneMountPath} for {fileName}");
            var foundFiles = Directory.GetFiles(Settings.Get.DownloadClient.RcloneMountPath, fileName, SearchOption.AllDirectories);

            if (foundFiles.Any())
            {
                if (foundFiles.Length > 1)
                {
                    _logger.Warning($"Found {foundFiles.Length} files named {fileName}");
                }

                var actualFilePath = foundFiles.First();
                var result = TryCreateSymbolicLink(actualFilePath, _filePath);

                if (result)
                {
                    DownloadComplete?.Invoke(this, new DownloadCompleteEventArgs());
                    _logger.Information($"File {fileName} found on {Settings.Get.DownloadClient.RcloneMountPath} at {actualFilePath}");
                    return Task.FromResult<String?>(actualFilePath);
                }
            }
        }

        _logger.Information($"File/Folder {fileName} not found on {Settings.Get.DownloadClient.RcloneMountPath}!");
        return Task.FromResult<String?>(null);
    }

    public Task Cancel()
    {
        _logger.Debug($"Cancelling download {_uri}");

        _cancellationToken.Cancel(false);

        return Task.CompletedTask;
    }

    public Task Pause()
    {
        return Task.CompletedTask;
    }

    public Task Resume()
    {
        return Task.CompletedTask;
    }

    private Boolean TryCreateSymbolicLink(String sourcePath, String symlinkPath)
    {
        try
        {
            _logger.Information($"Creating symbolic link from {sourcePath} to {symlinkPath}");

            File.CreateSymbolicLink(symlinkPath, sourcePath);

            if (File.Exists(symlinkPath))
            {
                _logger.Information($"Created symbolic link from {sourcePath} to {symlinkPath}");
                return true;
            }

            _logger.Error($"Failed to create symbolic link from {sourcePath} to {symlinkPath}");
            return false;
        }
        catch (Exception ex)
        {
            _logger.Error($"Error creating symbolic link from {sourcePath} to {symlinkPath}: {ex.Message}");
            return false;
        }
    }
}
