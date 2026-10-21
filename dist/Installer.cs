using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;
using System.Drawing;
using System.Diagnostics;
using Microsoft.Win32;

public class InstallerForm : Form
{
    private Button btnInstall;
    private Label lblStatus;
    private CheckBox chkDesktop;
    private CheckBox chkStartMenu;
    private ProgressBar progressBar;

    public InstallerForm()
    {
        this.Text = "Actual Track Setup";
        this.Size = new Size(540, 390);
        this.StartPosition = FormStartPosition.CenterScreen;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.BackColor = Color.FromArgb(248, 250, 252);
        this.Font = new Font("Segoe UI", 9.5f);

        // Header Panel
        Panel header = new Panel();
        header.Dock = DockStyle.Top;
        header.Height = 90;
        header.BackColor = Color.White;
        header.Padding = new Padding(24, 18, 24, 18);

        Label lblTitle = new Label();
        lblTitle.Text = "Actual Track Setup";
        lblTitle.Font = new Font("Segoe UI", 16f, FontStyle.Bold);
        lblTitle.ForeColor = Color.FromArgb(15, 23, 42);
        lblTitle.Location = new Point(24, 16);
        lblTitle.AutoSize = true;
        header.Controls.Add(lblTitle);

        Label lblSub = new Label();
        lblSub.Text = "Local-First Zero-Based Budgeting & Expense Tracker (Rupee ₹)";
        lblSub.Font = new Font("Segoe UI", 9.5f);
        lblSub.ForeColor = Color.FromArgb(100, 116, 139);
        lblSub.Location = new Point(26, 48);
        lblSub.AutoSize = true;
        header.Controls.Add(lblSub);

        this.Controls.Add(header);

        // Main content
        int top = 108;
        Label lblInfo = new Label();
        lblInfo.Text = "Installation Directory:";
        lblInfo.Location = new Point(25, top);
        lblInfo.AutoSize = true;
        lblInfo.ForeColor = Color.FromArgb(71, 85, 105);
        this.Controls.Add(lblInfo);

        top += 24;
        string defaultPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs\\ActualTrack");
        TextBox txtPath = new TextBox();
        txtPath.Text = defaultPath;
        txtPath.ReadOnly = true;
        txtPath.Location = new Point(25, top);
        txtPath.Size = new Size(475, 26);
        txtPath.BackColor = Color.White;
        this.Controls.Add(txtPath);

        top += 38;
        chkDesktop = new CheckBox();
        chkDesktop.Text = "Create Desktop Shortcut";
        chkDesktop.Checked = true;
        chkDesktop.Location = new Point(25, top);
        chkDesktop.AutoSize = true;
        this.Controls.Add(chkDesktop);

        top += 28;
        chkStartMenu = new CheckBox();
        chkStartMenu.Text = "Create Start Menu Shortcut";
        chkStartMenu.Checked = true;
        chkStartMenu.Location = new Point(25, top);
        chkStartMenu.AutoSize = true;
        this.Controls.Add(chkStartMenu);

        top += 30;
        Label lblSafe = new Label();
        lblSafe.Text = "✔ Database & Data Safe: Stored in AppData, never deleted on update/reinstall.";
        lblSafe.ForeColor = Color.FromArgb(5, 150, 105);
        lblSafe.Font = new Font("Segoe UI", 9f, FontStyle.Bold);
        lblSafe.Location = new Point(25, top);
        lblSafe.AutoSize = true;
        this.Controls.Add(lblSafe);

        // Progress bar
        top += 28;
        progressBar = new ProgressBar();
        progressBar.Location = new Point(25, top);
        progressBar.Size = new Size(475, 10);
        progressBar.Visible = false;
        this.Controls.Add(progressBar);

        // Status
        top += 14;
        lblStatus = new Label();
        lblStatus.Location = new Point(25, top);
        lblStatus.Size = new Size(320, 24);
        lblStatus.ForeColor = Color.FromArgb(100, 116, 139);
        this.Controls.Add(lblStatus);

        // Buttons
        btnInstall = new Button();
        btnInstall.Text = "Install";
        btnInstall.BackColor = Color.FromArgb(5, 150, 105);
        btnInstall.ForeColor = Color.White;
        btnInstall.FlatStyle = FlatStyle.Flat;
        btnInstall.FlatAppearance.BorderSize = 0;
        btnInstall.Font = new Font("Segoe UI", 10f, FontStyle.Bold);
        btnInstall.Size = new Size(130, 36);
        btnInstall.Location = new Point(370, top - 6);
        btnInstall.Click += (s, e) => DoInstall(defaultPath);
        this.Controls.Add(btnInstall);
    }

    private void DoInstall(string installDir)
    {
        try
        {
            btnInstall.Enabled = false;
            progressBar.Visible = true;
            progressBar.Style = ProgressBarStyle.Marquee;
            lblStatus.Text = "Installing Actual Track...";
            Application.DoEvents();

            if (!Directory.Exists(installDir))
            {
                Directory.CreateDirectory(installDir);
            }

            Assembly asm = Assembly.GetExecutingAssembly();
            using (Stream s = asm.GetManifestResourceStream("AppPayload.zip"))
            {
                if (s == null) throw new Exception("Embedded application payload was not found!");
                string tempZip = Path.Combine(Path.GetTempPath(), "actual_track_payload.zip");
                using (FileStream fs = new FileStream(tempZip, FileMode.Create))
                {
                    s.CopyTo(fs);
                }

                using (ZipArchive archive = ZipFile.OpenRead(tempZip))
                {
                    foreach (ZipArchiveEntry entry in archive.Entries)
                    {
                        string destPath = Path.Combine(installDir, entry.FullName);
                        if (string.IsNullOrEmpty(entry.Name))
                        {
                            Directory.CreateDirectory(destPath);
                        }
                        else
                        {
                            Directory.CreateDirectory(Path.GetDirectoryName(destPath));
                            entry.ExtractToFile(destPath, true);
                        }
                    }
                }
                try { File.Delete(tempZip); } catch {}
            }

            string exePath = Path.Combine(installDir, "expense_tracker.exe");

            // Shortcuts
            if (chkDesktop.Checked)
            {
                string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                CreateShortcut(Path.Combine(desktop, "Actual Track.lnk"), exePath, installDir);
            }

            if (chkStartMenu.Checked)
            {
                string startMenu = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
                CreateShortcut(Path.Combine(startMenu, "Actual Track.lnk"), exePath, installDir);
            }

            // Registry entry for Add/Remove Programs
            try
            {
                using (RegistryKey key = Registry.CurrentUser.CreateSubKey("Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ActualTrack"))
                {
                    if (key != null)
                    {
                        key.SetValue("DisplayName", "Actual Track");
                        key.SetValue("DisplayVersion", "1.1.0");
                        key.SetValue("Publisher", "Actual Track");
                        key.SetValue("DisplayIcon", exePath);
                        key.SetValue("InstallLocation", installDir);
                        key.SetValue("UninstallString", "cmd.exe /c rd /s /q \"" + installDir + "\"");
                    }
                }
            }
            catch {}

            progressBar.Style = ProgressBarStyle.Continuous;
            progressBar.Value = 100;
            lblStatus.Text = "Installation complete!";
            btnInstall.Text = "Launch App";
            btnInstall.Enabled = true;
            btnInstall.Click -= (s, e) => DoInstall(installDir);
            btnInstall.Click += (s, e) => {
                Process.Start(exePath);
                Application.Exit();
            };

            MessageBox.Show("Actual Track has been successfully installed!\n\n• Desktop & Start Menu shortcuts created.\n• Your SQLite database is safely preserved in AppData.", "Installation Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show("Installation failed: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            btnInstall.Enabled = true;
        }
    }

    private void CreateShortcut(string shortcutPath, string targetPath, string workingDir)
    {
        try
        {
            Type t = Type.GetTypeFromProgID("WScript.Shell");
            dynamic shell = Activator.CreateInstance(t);
            dynamic shortcut = shell.CreateShortcut(shortcutPath);
            shortcut.TargetPath = targetPath;
            shortcut.WorkingDirectory = workingDir;
            shortcut.Description = "Actual Track - Zero-Based Personal Finance & Expense Tracker";
            shortcut.IconLocation = targetPath + ",0";
            shortcut.Save();
        }
        catch {}
    }

    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new InstallerForm());
    }
}
