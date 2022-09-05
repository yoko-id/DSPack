Unit UnitMain;

Interface

Uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, System.ImageList,
  Vcl.ImgList, DSPack, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons;

Type
  PPlayListItem = ^TPlayListItem;

  TPlayListItem = Record
    Filename: String;
    Path: String;
  End;

  TForm1 = Class(TForm)
    Splitter1: TSplitter;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Label3: TLabel;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    Bevel1: TBevel;
    SoundLevel: TTrackBar;
    Panel3: TPanel;
    DSTrackBar1: TDSTrackBar;
    VideoWindow: TVideoWindow;
    Panel2: TPanel;
    Panel4: TPanel;
    ListBox1: TListBox;
    FilterGraph1: TFilterGraph;
    OpenDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Open1: TMenuItem;
    Exit1: TMenuItem;
    ImageList1: TImageList;
    PopupMenu1: TPopupMenu;
    Play1: TMenuItem;
    Pause1: TMenuItem;
    Stop1: TMenuItem;
    N2: TMenuItem;
    Fullscreen1: TMenuItem;
    N3: TMenuItem;
    Exit2: TMenuItem;
    ImageList2: TImageList;
    PopupMenu2: TPopupMenu;
    Add1: TMenuItem;
    Remove1: TMenuItem;
    Clear1: TMenuItem;
    Procedure PlayFile(Filename: String);
    Procedure FormCreate(Sender: TObject);
    Procedure Open1Click(Sender: TObject);
    Procedure SpeedButton1Click(Sender: TObject);
    Procedure SpeedButton2Click(Sender: TObject);
    Procedure SpeedButton3Click(Sender: TObject);
    Procedure SpeedButton6Click(Sender: TObject);
    Procedure SpeedButton7Click(Sender: TObject);
    Procedure Exit1Click(Sender: TObject);
    Procedure SoundLevelChange(Sender: TObject);
    Procedure Add1Click(Sender: TObject);
    Procedure ListBox1DblClick(Sender: TObject);
    Procedure Clear1Click(Sender: TObject);
  Private
    { Private declarations }
  Public
    { Public declarations }
    PlayListItem: PPlayListItem;
    PlayingIndex: Integer;
  End;

Var
  Form1: TForm1;

Implementation

{$R *.dfm}

Procedure TForm1.PlayFile(Filename: String);
Begin
  FilterGraph1.ClearGraph;

  // --------------------------------------------------------------------------------------
  // This is a workaround the problem that we don't always get the EC_CLOCK_CHANGED.
  // and because we didn't get the EC_CLOCK_CHANGED the DSTrackbar and DSVideoWindowEx1
  // didn't got reassigned and that returned in misfuntions.
  FilterGraph1.Active := False;
  FilterGraph1.Active := True;
  // --------------------------------------------------------------------------------------

  FilterGraph1.RenderFile(FileName);
  SoundLevel.Position := FilterGraph1.Volume;
  FilterGraph1.Play;
  // CheckColorControlSupport;
End;

Procedure TForm1.SoundLevelChange(Sender: TObject);
Begin
  FilterGraph1.Volume := SoundLevel.Position;
End;

Procedure TForm1.SpeedButton1Click(Sender: TObject);
Begin
  If Not FilterGraph1.Active Then Open1Click(Nil)
  Else FilterGraph1.Play;
End;

Procedure TForm1.SpeedButton2Click(Sender: TObject);
Begin
  FilterGraph1.Pause;
End;

Procedure TForm1.SpeedButton3Click(Sender: TObject);
Begin
  FilterGraph1.Stop;
End;

Procedure TForm1.SpeedButton6Click(Sender: TObject);
Var
  Filename: String;
Begin
  If Playingindex > 0 Then Begin
    Listbox1.ItemIndex := ListBox1.ItemIndex - 1;
    PlayListItem := PPlayListItem(Listbox1.Items.Objects[Listbox1.ItemIndex]);
    Filename := PlayListItem^.Path;
    If Filename[Length(Filename)] <> '\' Then Filename := Filename + '\';
    Filename := Filename + PlayListItem^.Filename;
    PlayFile(Filename);
    PlayingIndex := Listbox1.Itemindex;
  End;
  If PlayingIndex > 0 Then SpeedButton6.Enabled := True
  Else SpeedButton6.Enabled := False;
  If PlayingIndex < Listbox1.Items.Count - 1 Then SpeedButton7.Enabled := True
  Else SpeedButton7.Enabled := False;

End;

Procedure TForm1.SpeedButton7Click(Sender: TObject);
Var
  Filename: String;
Begin
  If Playingindex < Listbox1.Items.Count - 1 Then Begin
    Listbox1.ItemIndex := ListBox1.ItemIndex + 1;
    PlayListItem := PPlayListItem(Listbox1.Items.Objects[Listbox1.ItemIndex]);
    Filename := PlayListItem^.Path;
    If Filename[Length(Filename)] <> '\' Then Filename := Filename + '\';
    Filename := Filename + PlayListItem^.Filename;
    PlayFile(Filename);
    PlayingIndex := Listbox1.Itemindex;
  End;
  If PlayingIndex > 0 Then SpeedButton6.Enabled := True
  Else SpeedButton6.Enabled := False;
  If PlayingIndex < Listbox1.Items.Count - 1 Then SpeedButton7.Enabled := True
  Else SpeedButton7.Enabled := False;

End;

Procedure TForm1.Add1Click(Sender: TObject);
Var
  I: Integer;
Begin
  If ListBox1.Items.Count < 1 Then Begin
    Open1Click(Nil);
    SpeedButton6.Enabled := False;
    SpeedButton7.Enabled := False;
    Exit;
  End;
  If OpenDialog1.Execute Then Begin
    With OpenDialog1.Files Do
      // Now go thru every files selected in the opendialog and add
      // them one by one to the Players playlist.
      // The first file added to the players playlist will loaded
      // automaticly
      For I := Count - 1 Downto 0 Do Begin
        New(PlayListItem);
        PlayListItem^.Filename := ExtractFilename(Strings[I]);
        PlayListItem^.Path := ExtractFilePath(Strings[I]);
        ListBox1.Items.AddObject(PlayListItem^.Filename, TObject(PlayListItem));
      End;
  End;
  If PlayingIndex > 0 Then SpeedButton6.Enabled := True;
  If PlayingIndex < Listbox1.Items.Count - 1 Then SpeedButton7.Enabled := True;

End;

Procedure TForm1.Clear1Click(Sender: TObject);
Begin
  FilterGraph1.Stop;
  FilterGraph1.ClearGraph;
  FilterGraph1.Active := False;
  Listbox1.Items.Clear;
End;

Procedure TForm1.Exit1Click(Sender: TObject);
Begin
  FilterGraph1.ClearGraph;
  { FilterGraph1.Active := false;
    Application.Terminate; }
End;

Procedure TForm1.FormCreate(Sender: TObject);
Var
  I: Integer;
Begin
  Imagelist1.GetBitmap(3, SpeedButton1.Glyph);
  Imagelist1.GetBitmap(2, SpeedButton2.Glyph);
  Imagelist1.GetBitmap(4, SpeedButton3.Glyph);
  //Imagelist1.GetBitmap(9, SpeedButton4.Glyph);
 // Imagelist1.GetBitmap(8, SpeedButton13.Glyph);
  Imagelist1.GetBitmap(0, SpeedButton6.Glyph);
  Imagelist1.GetBitmap(6, SpeedButton7.Glyph);

  { Case VideoWindow.AspectRatio Of
    RmStretched: Stretched1.Checked := True;
    RmLetterBox: LetterBox1.Checked := True;
    RmCrop: Crop1.Checked := True;
    End; }

End;

Procedure TForm1.ListBox1DblClick(Sender: TObject);
Var
  Filename: String;
Begin
  If ListBox1.ItemIndex = PlayingIndex Then Exit;
  PlayListItem := PPlayListitem(Listbox1.Items.Objects[ListBox1.Itemindex]);
  Filename := PlayListItem^.Path;
  If Filename[Length(Filename)] <> '\' Then Filename := Filename + '\';
  Filename := Filename + PlayListItem^.Filename;
  PlayFile(Filename);
  PlayingIndex := Listbox1.Itemindex;
  If PlayingIndex > 0 Then SpeedButton6.Enabled := True
  Else SpeedButton6.Enabled := False;
  If PlayingIndex < Listbox1.Items.Count - 1 Then SpeedButton7.Enabled := True
  Else SpeedButton7.Enabled := False;
End;

Procedure TForm1.Open1Click(Sender: TObject);
Var
  I: Integer;
Begin
  // The Add file to playerlist was selected.
  If OpenDialog1.Execute Then Begin
    Listbox1.Items.Clear;
    With OpenDialog1.Files Do
      // Now go thru every files selected in the opendialog and add
      // them one by one to the Players playlist.
      // The first file added to the players playlist will loaded
      // automaticly
      For I := Count - 1 Downto 0 Do Begin
        New(PlayListItem);
        PlayListItem^.Filename := ExtractFilename(Strings[I]);
        PlayListItem^.Path := ExtractFilePath(Strings[I]);
        ListBox1.Items.AddObject(PlayListItem^.Filename, TObject(PlayListItem));
      End;
    Listbox1.ItemIndex := 0;
    PlayFile(OpenDialog1.Files.Strings[0]);
    PlayingIndex := 0;
  End;
  If PlayingIndex < Listbox1.Items.Count - 1 Then SpeedButton7.Enabled := True;

End;

End.
