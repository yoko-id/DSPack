(* ********************************************************************
  *  DSPack 2.3.3                                                     *
  *                                                                   *
  *  home page : http://www.progdigy.com                              *
  *  email     : hgourvest@progdigy.com                               *
  *   Thanks to Michael Andersen. (DSVideoWindowEx)                   *
  *                                                                   *
  *  date      : 2003-09-08                                           *
  *                                                                   *
  *  The contents of this file are used with permission, subject to   *
  *  the Mozilla Public License Version 1.1 (the "License"); you may  *
  *  not use this file except in compliance with the License. You may *
  *  obtain a copy of the License at                                  *
  *  http://www.mozilla.org/MPL/MPL-1.1.html                          *
  *                                                                   *
  *  Software distributed under the License is distributed on an      *
  *  "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   *
  *  implied. See the License for the specific language governing     *
  *  rights and limitations under the License.                        *
  *                                                                   *
  *  Contributor(s)                                                   *
  *    Peter J. Haas     <DSPack@pjh2.de>                             *
  *    Andriy Nevhasymyy <a.n@email.com>                              *
  *    Milenko Mitrovic  <dcoder@dsp-worx.de>                         *
  *    Michael Andersen  <michael@mechdata.dk>                        *
  *    Martin Offenwanger <coder@dsplayer.de>                         *
  *                                                                   *
  ******************************************************************** *)

{$I dspack.inc}
{$IFDEF COMPILER6_UP}
{$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
{$IFDEF COMPILER7_UP}
{$WARN SYMBOL_DEPRECATED OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CAST OFF}
{$ENDIF}
{$ALIGN ON}
{$MINENUMSIZE 4}
Unit DSPack;

Interface

Uses
  Windows, Classes, SysUtils, Messages, Graphics, Forms, Controls, ActiveX, DirectShow9,
  DirectDraw, DXSUtil, ComCtrls, MMSystem, Math, Consts, ExtCtrls,
  MultiMon, Dialogs, Registry, SyncObjs, Direct3D9, WMF9;

Const
  { Filter Graph message identifier. }
  WM_GRAPHNOTIFY = WM_APP + 1;
  { Sample Grabber message identifier. }
  WM_CAPTURE_BITMAP = WM_APP + 2;

Type

  { Video mode to use with @link(TVideoWindow). }
  TVideoMode = (VmNormal, VmVMR);

  { Graph Mode to use with @link(TFilterGraph). }
  TGraphMode = (GmNormal, GmCapture, GmDVD);

  { Render device returned by then OnGraphVMRRenderDevice event. }
{$IFDEF VER140}
  TVMRRenderDevice = (RdOverlay = 1, RdVidMem = 2, RdSysMem = 4);
{$ELSE}
  TVMRRenderDevice = Integer;

Const
  RdOverlay = 1;
  RdVidMem = 2;
  RdSysMem = 4;

Type
{$ENDIF}
  { @exclude }
  TGraphState = (GsUninitialized, GsStopped, GsPaused, GsPlaying);

  { Specifies the seeking capabilities of a media stream. }
  TSeekingCap = (CanSeekAbsolute, // The stream can seek to an absolute position.
    CanSeekForwards, // The stream can seek forward.
    CanSeekBackwards, // The stream can seek backward.
    CanGetCurrentPos, // The stream can report its current position.
    CanGetStopPos, // The stream can report its stop position.
    CanGetDuration, // The stream can report its duration.
    CanPlayBackwards, // The stream can play backward.
    CanDoSegments, // The stream can do seamless looping (see IMediaSeeking.SetPositions).
    Source // Reserved.
    );
  { Specifies the seeking capabilities of a media stream. }
  TSeekingCaps = Set Of TSeekingCap;

  { Video Mixer Render Preferences: <br>
    <b>vpForceOffscreen:</b> Indicates that the VMR should use only offscreen surfaces for rendering.<br>
    <b>vpForceOverlays:</b> Indicates that the VMR should fail if no overlay surfaces are available.<br>
    <b>vpForceMixer:</b> Indicates that the VMR must use Mixer when the number of streams is 1.<br>
    <b>vpDoNotRenderColorKeyAndBorder:</b> Indicates that the application is responsible for painting the color keys.<br>
    <b>vpRestrictToInitialMonitor:</b> Indicates that the VMR should output only to the initial monitor.<br>
    <b>vpPreferAGPMemWhenMixing:</b> Indicates that the VMR should attempt to use AGP memory when allocating texture surfaces. }
  TVMRPreference = (VpForceOffscreen, VpForceOverlays, VpForceMixer, VpDoNotRenderColorKeyAndBorder, VpRestrictToInitialMonitor, VpPreferAGPMemWhenMixing);

  { Pointer to @link(TVMRPreferences). }
  PVMRPreferences = ^TVMRPreferences;
  { Set of @link(TVMRPreference). }
  TVMRPreferences = Set Of TVMRPreference;

  TOnDSEvent = Procedure(Sender: TComponent; Event: Integer; Param1, Param2: NativeInt) Of Object;
  { @exclude }
  TOnGraphBufferingData = Procedure(Sender: TObject; Buffering: Boolean) Of Object; { @exclude }
  TOnGraphComplete = Procedure(Sender: TObject; Result: HRESULT; Renderer: IBaseFilter) Of Object; { @exclude }
  TOnGraphDeviceLost = Procedure(Sender: TObject; Device: IUnknown; Removed: Boolean) Of Object; { @exclude }
  TOnGraphEndOfSegment = Procedure(Sender: TObject; StreamTime: TReferenceTime; NumSegment: Cardinal) Of Object; { @exclude }
  TOnDSResult = Procedure(Sender: TObject; Result: HRESULT) Of Object; { @exclude }
  TOnGraphFullscreenLost = Procedure(Sender: TObject; Renderer: IBaseFilter) Of Object; { @exclude }
  TOnGraphOleEvent = Procedure(Sender: TObject; String1, String2: UnicodeString) Of Object; { @exclude }
  TOnGraphOpeningFile = Procedure(Sender: TObject; Opening: Boolean) Of Object; { @exclude }
  TOnGraphSNDDevError = Procedure(Sender: TObject; OccurWhen: TSndDevErr; ErrorCode: LongWord) Of Object; { @exclude }
  TOnGraphStreamControl = Procedure(Sender: TObject; PinSender: IPin; Cookie: LongWord) Of Object; { @exclude }
  TOnGraphStreamError = Procedure(Sender: TObject; Operation: HRESULT; Value: LongWord) Of Object; { @exclude }
  TOnGraphVideoSizeChanged = Procedure(Sender: TObject; Width, Height: Word) Of Object; { @exclude }
  TOnGraphTimeCodeAvailable = Procedure(Sender: TObject; From: IBaseFilter; DeviceID: LongWord) Of Object; { @exclude }
  TOnGraphEXTDeviceModeChange = Procedure(Sender: TObject; NewMode, DeviceID: LongWord) Of Object; { @exclude }
  TOnGraphVMRRenderDevice = Procedure(Sender: TObject; RenderDevice: TVMRRenderDevice) Of Object;
  { @exclude }
  TOnDVDAudioStreamChange = Procedure(Sender: TObject; Stream, Lcid: Integer; Lang: String) Of Object; { @exclude }
  TOnDVDCurrentTime = Procedure(Sender: TObject; Hours, Minutes, Seconds, Frames, Frate: Integer) Of Object; { @exclude }
  TOnDVDTitleChange = Procedure(Sender: TObject; Title: Integer) Of Object; { @exclude }
  TOnDVDChapterStart = Procedure(Sender: TObject; Chapter: Integer) Of Object; { @exclude }
  TOnDVDValidUOPSChange = Procedure(Sender: TObject; UOPS: Integer) Of Object; { @exclude }
  TOnDVDChange = Procedure(Sender: TObject; Total, Current: Integer) Of Object; { @exclude }
  TOnDVDStillOn = Procedure(Sender: TObject; NoButtonAvailable: Boolean; Seconds: Integer) Of Object; { @exclude }
  TOnDVDSubpictureStreamChange = Procedure(Sender: TObject; SubNum, Lcid: Integer; Lang: String) Of Object; { @exclude }
  TOnDVDPlaybackRateChange = Procedure(Sender: TObject; Rate: Single) Of Object; { @exclude }
  TOnDVDParentalLevelChange = Procedure(Sender: TObject; Level: Integer) Of Object; { @exclude }
  TOnDVDAnglesAvailable = Procedure(Sender: TObject; Available: Boolean) Of Object; { @exclude }
  TOnDVDButtonAutoActivated = Procedure(Sender: TObject; Button: Cardinal) Of Object; { @exclude }
  TOnDVDCMD = Procedure(Sender: TObject; CmdID: Cardinal) Of Object; { @exclude }
  TOnDVDCurrentHMSFTime = Procedure(Sender: TObject; HMSFTimeCode: TDVDHMSFTimeCode; TimeCode: TDsPackDVDTimecode) Of Object; { @exclude }
  TOnDVDKaraokeMode = Procedure(Sender: TObject; Played: Boolean) Of Object;
  { @exclude }
  TOnBuffer = Procedure(Sender: TObject; SampleTime: Double; PBuffer: Pointer; BufferLen: Longint) Of Object;

  TOnSelectedFilter = Function(Moniker: IMoniker; FilterName: UnicodeString; ClassID: TGuid): Boolean Of Object;
  TOnCreatedFilter = Function(Filter: IBaseFilter; ClassID: TGuid): Boolean Of Object;
  TOnUnableToRender = Function(Pin: IPin): Boolean Of Object;
  // *****************************************************************************
  // IFilter
  // *****************************************************************************

  { @exclude }
  TFilterOperation = (FoAdding, // Before the filter is added to graph.
    FoAdded, // After the filter is added to graph.
    FoRemoving, // Before the filter is removed from graph.
    FoRemoved, // After the filter is removed from graph.
    FoRefresh // Designer notification to Refresh the filter .
    );

  { @exclude }
  IFilter = Interface
    ['{887F94DA-29E9-44C6-B48E-1FBF0FB59878}']
    { Return the IBaseFilter Interface (All DirectShow filters expose this interface). }
    Function GetFilter: IBaseFilter;
    { Return the filter name (generally the component name). }
    Function GetName: String;
    { Called by the @link(TFilterGraph) component, this method receive notifications
      on what the TFilterGraph is doing. if Operation = foGraphEvent then Param is the
      event code received by the FilterGraph. }
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
  End;

  { @exclude }
  TControlEvent = (CePlay, CePause, CeStop, CeFileRendering, CeFileRendered, CeDVDRendering, CeDVDRendered, CeActive);

  { @exclude }
  IEvent = Interface
    ['{6C0DCD7B-1A98-44EF-A6D5-E23CBC24E620}']
    { FilterGraph events. }
    Procedure GraphEvent(Event, Param1, Param2: Integer);
    { Control Events. }
    Procedure ControlEvent(Event: TControlEvent; Param: Integer = 0);
  End;



  // *****************************************************************************
  // TFilterGraph
  // *****************************************************************************

  { This component is the central component in DirectShow, the Filter Graph
    handle synchronization, event notification, and other aspects of the
    controlling the filter graph. }
  TFilterGraph = Class(TComponent, IAMGraphBuilderCallback, IAMFilterGraphCallback, IServiceProvider)
  Private
    FActive: Boolean;
    FAutoCreate: Boolean;
    FHandle: THandle; // to capture events
    FMode: TGraphMode;

    FVolume: Integer;
    FBalance: Integer;
    FRate: Double;
    FLinearVolume: Boolean;

    FFilters: TInterfaceList;
    FGraphEvents: TInterfaceList;

    // builders
    FFilterGraph: IGraphBuilder;
    FCaptureGraph: ICaptureGraphBuilder2;
    FDVDGraph: IDvdGraphBuilder;

    // events interface
    FMediaEventEx: IMediaEventEx;

    // Graphedit
    FGraphEdit: Boolean;
    FGraphEditID: Integer;

    // Log File
    FLogFileName: String;
    FLogFile: TFileStream;

    FOnActivate: TNotifyEvent;

    // All Events Code
    FOnDSEvent: TOnDSEvent;
    // Generic Graph Events
    FOnGraphBufferingData: TOnGraphBufferingData;
    FOnGraphClockChanged: TNotifyEvent;
    FOnGraphComplete: TOnGraphComplete;
    FOnGraphDeviceLost: TOnGraphDeviceLost;
    FOnGraphEndOfSegment: TOnGraphEndOfSegment;
    FOnGraphErrorStillPlaying: TOnDSResult;
    FOnGraphErrorAbort: TOnDSResult;
    FOnGraphFullscreenLost: TOnGraphFullscreenLost;
    FOnGraphChanged: TNotifyEvent;
    FOnGraphOleEvent: TOnGraphOleEvent;
    FOnGraphOpeningFile: TOnGraphOpeningFile;
    FOnGraphPaletteChanged: TNotifyEvent;
    FOnGraphPaused: TOnDSResult;
    FOnGraphQualityChange: TNotifyEvent;
    FOnGraphSNDDevInError: TOnGraphSNDDevError;
    FOnGraphSNDDevOutError: TOnGraphSNDDevError;
    FOnGraphStepComplete: TNotifyEvent;
    FOnGraphStreamControlStarted: TOnGraphStreamControl;
    FOnGraphStreamControlStopped: TOnGraphStreamControl;
    FOnGraphStreamErrorStillPlaying: TOnGraphStreamError;
    FOnGraphStreamErrorStopped: TOnGraphStreamError;
    FOnGraphUserAbort: TNotifyEvent;
    FOnGraphVideoSizeChanged: TOnGraphVideoSizeChanged;
    FOnGraphTimeCodeAvailable: TOnGraphTimeCodeAvailable;
    FOnGraphEXTDeviceModeChange: TOnGraphEXTDeviceModeChange;
    FOnGraphClockUnset: TNotifyEvent;
    FOnGraphVMRRenderDevice: TOnGraphVMRRenderDevice;

    FOnDVDAudioStreamChange: TOnDVDAudioStreamChange;
    FOnDVDCurrentTime: TOnDVDCurrentTime;
    FOnDVDTitleChange: TOnDVDTitleChange;
    FOnDVDChapterStart: TOnDVDChapterStart;
    FOnDVDAngleChange: TOnDVDChange;
    FOnDVDValidUOPSChange: TOnDVDValidUOPSChange;
    FOnDVDButtonChange: TOnDVDChange;
    FOnDVDChapterAutoStop: TNotifyEvent;
    FOnDVDStillOn: TOnDVDStillOn;
    FOnDVDStillOff: TNotifyEvent;
    FOnDVDSubpictureStreamChange: TOnDVDSubpictureStreamChange;
    FOnDVDNoFP_PGC: TNotifyEvent;
    FOnDVDPlaybackRateChange: TOnDVDPlaybackRateChange;
    FOnDVDParentalLevelChange: TOnDVDParentalLevelChange;
    FOnDVDPlaybackStopped: TNotifyEvent;
    FOnDVDAnglesAvailable: TOnDVDAnglesAvailable;
    FOnDVDPlayPeriodAutoStop: TNotifyEvent;
    FOnDVDButtonAutoActivated: TOnDVDButtonAutoActivated;
    FOnDVDCMDStart: TOnDVDCMD;
    FOnDVDCMDEnd: TOnDVDCMD;
    FOnDVDDiscEjected: TNotifyEvent;
    FOnDVDDiscInserted: TNotifyEvent;
    FOnDVDCurrentHMSFTime: TOnDVDCurrentHMSFTime;
    FOnDVDKaraokeMode: TOnDVDKaraokeMode;
    // DVD Warning
    FOnDVDWarningInvalidDVD1_0Disc: TNotifyEvent; // =1,
    FOnDVDWarningFormatNotSupported: TNotifyEvent; // =2,
    FOnDVDWarningIllegalNavCommand: TNotifyEvent; // =3
    FOnDVDWarningOpen: TNotifyEvent; // =4
    FOnDVDWarningSeek: TNotifyEvent; // =5
    FOnDVDWarningRead: TNotifyEvent; // =6
    // DVDDomain
    FOnDVDDomainFirstPlay: TNotifyEvent;
    FOnDVDDomainVideoManagerMenu: TNotifyEvent;
    FOnDVDDomainVideoTitleSetMenu: TNotifyEvent;
    FOnDVDDomainTitle: TNotifyEvent;
    FOnDVDDomainStop: TNotifyEvent;
    // DVDError
    FOnDVDErrorUnexpected: TNotifyEvent;
    FOnDVDErrorCopyProtectFail: TNotifyEvent;
    FOnDVDErrorInvalidDVD1_0Disc: TNotifyEvent;
    FOnDVDErrorInvalidDiscRegion: TNotifyEvent;
    FOnDVDErrorLowParentalLevel: TNotifyEvent;
    FOnDVDErrorMacrovisionFail: TNotifyEvent;
    FOnDVDErrorIncompatibleSystemAndDecoderRegions: TNotifyEvent;
    FOnDVDErrorIncompatibleDiscAndDecoderRegions: TNotifyEvent;

    FOnSelectedFilter: TOnSelectedFilter;
    FOnCreatedFilter: TOnCreatedFilter;
    FOnUnableToRender: TOnUnableToRender;

    Procedure HandleEvents;
    Procedure WndProc(Var Msg: TMessage);
    Procedure SetActive(Activate: Boolean);
    Procedure SetGraphMode(Mode: TGraphMode);
    Procedure SetGraphEdit(Enable: Boolean);
    Procedure ClearOwnFilters;
    Procedure AddOwnFilters;
    Procedure GraphEvents(Event, Param1, Param2: Integer);
    Procedure ControlEvents(Event: TControlEvent; Param: Integer = 0);
    Procedure SetLogFile(FileName: String);
    Function GetState: TGraphState;
    Procedure SetState(Value: TGraphState);
    Procedure SetVolume(Volume: Integer);
    Procedure SetBalance(Balance: Integer);
    Function GetSeekCaps: TSeekingCaps;
    Procedure SetRate(Rate: Double);
    Function GetDuration: Integer;
    Procedure SetLinearVolume(AEnabled: Boolean);
    Procedure UpdateGraph;
    Function GetPosition: Integer;
    Procedure SetPosition(APosition: Integer);

    // IAMGraphBuilderCallback
    Function SelectedFilter(PMon: IMoniker): HResult; Stdcall;
    Function CreatedFilter(PFil: IBaseFilter): HResult; Stdcall;

    // IAMFilterGraphCallback
    Function UnableToRender(Ph1, Ph2: Integer; PPin: IPin): HResult; // thiscall
  Protected
    { @exclude }
    Procedure DoEvent(Event: Integer; Param1, Param2: NativeInt); Virtual;
    { @exclude }
    Procedure InsertFilter(AFilter: IFilter);
    { @exclude }
    Procedure RemoveFilter(AFilter: IFilter);
    { @exclude }
    Procedure InsertEventNotifier(AEvent: IEvent);
    { @exclude }
    Procedure RemoveEventNotifier(AEvent: IEvent);
    { @exclude }
    Function QueryService(Const Rsid, Iid: TGuid; Out Obj): HResult; Stdcall;
  Public
    { Retrieve/Set the current Position in MilliSeconds. }
    Property Position: Integer Read GetPosition Write SetPosition;
    { Retrieve the total duration of a stream. }
    Property Duration: Integer Read GetDuration;
    { Retrieve/Set the rate. }
    Property Rate: Double Read FRate Write SetRate;
    { Retrieve the seeking capabilities. }
    Property SeekCapabilities: TSeekingCaps Read GetSeekCaps;
    { The volume balance. }
    Property Balance: Integer Read FBalance Write SetBalance;
    { The volume. }
    Property Volume: Integer Read FVolume Write SetVolume;
    { Current state of the filter graph. }
    Property State: TGraphState Read GetState Write SetState;
    { TFilterGraph constructor. }
    Constructor Create(AOwner: TComponent); Override;
    { TFilterGraph destructor. }
    Destructor Destroy; Override;
    { @exclude }
    Procedure Loaded; Override;
    { Retrieve an Interface from the current Graph.<br>
      <b>ex: </b> (FilterGraph <b>as</b> IGraphBuilder).RenderFile('C:\speedis.avi', <b>nil</b>);<br>
      <b>Remark: </b> The interfaces you can Query depend of the @link(Mode) you
      have defined.<br>
      <b>gmNormal: </b>IAMGraphStreams, IAMStats, IBasicAudio, IBasicVideo,
      IBasicVideo2, IFilterChain, IFilterGraph, IFilterGraph2,
      IFilterMapper2, IGraphBuilder, IGraphConfig, IGraphVersion,
      IMediaControl, IMediaEvent, IMediaEventEx, IMediaEventSink,
      IMediaFilter, IMediaPosition, IMediaSeeking, IQueueCommand,
      IRegisterServiceProvider, IResourceManager, IServiceProvider,
      IVideoFrameStep, IVideoWindow. <br>
      <b>gmCapture: </b> all gmNormal interfaces and ICaptureGraphBuilder2.<br>
      <b>gmDVD: </b> all gmNormal interfaces and IDvdGraphBuilder, IDvdControl2,
      IDvdInfo2, IAMLine21Decoder. }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;
    { The Run method runs all the filters in the filter graph. While the graph
      is running, data moves through the graph and is rendered. }
    Function Play: Boolean;
    { The Pause method pauses all the filters in the filter graph. }
    Function Pause: Boolean;
    { The Stop method stops all the filters in the graph. }
    Function Stop: Boolean;
    { This method disconnect all pins. }
    Procedure DisconnectFilters;
    { Disconnect and remove all filters from the filter graph excepting the custom components. }
    Procedure ClearGraph;
    { Render a single file. }
    Function RenderFile(FileName: UnicodeString): HRESULT;
    Function RenderFileEx(FileName: UnicodeString): HRESULT;
    { Render a DVD Video Volume or a File Name if specified. }
    Function RenderDVD(Out Status: TAMDVDRenderStatus; FileName: UnicodeString = ''; Mode: Integer = AM_DVD_HWDEC_PREFER): HRESULT;
    { Save the current state and position of a DVD movie to a file.<br>
      See also: @link(DVDRestoreBookmark). }
    Procedure DVDSaveBookmark(BookMarkFile: UnicodeString);
    { Restore the State and position of a DVD movie saved by @link(DVDSaveBookmark). }
    Procedure DVDRestoreBookmark(BookMarkFile: UnicodeString);
  Published

    { Specify a File Name to save the Filter Graph Log. }
    Property LogFile: String Read FLogFileName Write SetLogFile;

    { Activate the Filter Graph. }
    Property Active: Boolean Read FActive Write SetActive Default False;

    { Auto-Activate the Filter Graph when component is created. }
    Property AutoCreate: Boolean Read FAutoCreate Write FAutoCreate Default False;

    { There is 3 modes: gmNormal, gmCapture and gmDVD. <br>
      See also: @link(GraphInterFace). }
    Property Mode: TGraphMode Read FMode Write SetGraphMode Default GmNormal;

    { if true you can use GraphEdit application to connect with the Filter Graph. }
    Property GraphEdit: Boolean Read FGraphEdit Write SetGraphEdit;

    { if true, Volume and Balance is set by using a linear algorythm instead of
      logatithmic. }
    Property LinearVolume: Boolean Read FLinearVolume Write SetLinearVolume;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    Property OnActivate: TNotifyEvent Read FOnActivate Write FOnActivate;

    { Generic Filter Graph event.<br>
      <b>Event:</b> message sent.<br>
      <b>Param1:</b> first message parameter.<br>
      <b>Param2:</b> second message parameter. }
    Property OnDSEvent: TOnDSEvent Read FOnDSEvent Write FOnDSEvent;

    { The graph is buffering data, or has stopped buffering data.
      A filter can send this event if it needs to buffer data from an external
      source. (for example, it might be loading data from a network.)
      The application can use this event to adjust its user interface.<br>
      <b>buffering:</b> TRUE if the graph is starting to buffer, or FALSE if
      the graph has stopped buffering. }
    Property OnGraphBufferingData: TOnGraphBufferingData Read FOnGraphBufferingData Write FOnGraphBufferingData;

    { The reference clock has changed. The filter graph manager sends this event
      when its IMediaFilter.SetSyncSource method is called. }
    Property OnGraphClockChanged: TNotifyEvent Read FOnGraphClockChanged Write FOnGraphClockChanged;

    { All data from a particular stream has been rendered.
      By default, the filter graph manager does not forward this event to the
      application. However, after all the streams in the graph report EC_COMPLETE,
      the filter graph manager posts a separate EC_COMPLETE event to the application.<br>
      <b>Result:</b> HRESULT value; can be S_OK.<br>
      <b>Renderer:</b> nil, or a reference to the renderer's IBaseFilter interface. }
    Property OnGraphComplete: TOnGraphComplete Read FOnGraphComplete Write FOnGraphComplete;

    { A Plug and Play device was removed or became available again. When the
      device becomes available again, the previous state of the device filter is
      no longer valid. The application must rebuild the graph in order to use the device.<br>
      <b>Device:</b> IUnknown interface of the filter that represents the device.<br>
      <b>Removed:</b> True if the device was removed, or False if the device is available again. }
    Property OnGraphDeviceLost: TOnGraphDeviceLost Read FOnGraphDeviceLost Write FOnGraphDeviceLost;

    { The end of a segment was reached.
      This event code supports seamless looping. When a call to the IMediaSeeking.SetPositions
      method includes the AM_SEEKING_Segment flag, the source filter sends this
      event code instead of calling IPin.EndOfStream.<br>
      <b>StreamTime:</b> TREFERENCE_TIME value that specifies the accumulated stream time since the start of the segment.<br>
      <b>NumSegment:</b> Cardinal value indicating the segment number (zero-based). }
    Property OnGraphEndOfSegment: TOnGraphEndOfSegment Read FOnGraphEndOfSegment Write FOnGraphEndOfSegment;

    { An asynchronous command to run the graph has failed.
      if the filter graph manager issues an asynchronous run command that fails,
      it sends this event to the application. The graph remains in a running state.
      The state of the underlying filters is indeterminate. Some filters might be
      running, others might not.<br>
      <b>Result:</b> value of the operation that failed. }
    Property OnGraphErrorStillPlaying: TOnDSResult Read FOnGraphErrorStillPlaying Write FOnGraphErrorStillPlaying;

    { An operation was aborted because of an error.<br>
      <b>Result:</b> value of the operation that failed. }
    Property OnGraphErrorAbort: TOnDSResult Read FOnGraphErrorAbort Write FOnGraphErrorAbort;

    { The video renderer is switching out of full-screen mode.
      When the Full Screen Renderer loses activation, it sends this event. When
      another video renderer switches out of full-screen mode, the filter graph
      manager sends this event, in response to an EC_ACTIVATE event from the renderer.<br>
      <b>Renderer:</b> the video renderer's IBaseFilter interface, or nil. }
    Property OnGraphFullscreenLost: TOnGraphFullscreenLost Read FOnGraphFullscreenLost Write FOnGraphFullscreenLost;

    { The filter graph has changed.
      This event code is intended for debugging. It is not sent for all graph changes. }
    Property OnGraphChanged: TNotifyEvent Read FOnGraphChanged Write FOnGraphChanged;

    { A filter is passing a text string to the application.
      By convention, the first parameter contains type information (for example, Text)
      and the second parameter contains the text string.<br>
      <b>String1, String2:</b> Wide Strings }
    Property OnGraphOleEvent: TOnGraphOleEvent Read FOnGraphOleEvent Write FOnGraphOleEvent;

    { The graph is opening a file, or has finished opening a file.
      A filter can send this event if it spends significant time opening a file.
      (for example, the file might be located on a network.) The application can use
      this event to adjust its user interface.<br>
      <b>opening:</b> TRUE if the graph is starting to open a file, or FALSE
      if the graph is no longer opening the file. }
    Property OnGraphOpeningFile: TOnGraphOpeningFile Read FOnGraphOpeningFile Write FOnGraphOpeningFile;

    { The video palette has changed.
      Video renderers send this event if they detect a palette change in the stream. }
    Property OnGraphPaletteChanged: TNotifyEvent Read FOnGraphPaletteChanged Write FOnGraphPaletteChanged;

    { A pause request has completed.
      The filter graph manager sends this event when it completes an asynchronous pause command.<br>
      <b>Result:</b> value that indicates the result of the transition. if the
      value is S_OK, the filter graph is now in a paused state. }
    Property OnGraphPaused: TOnDSResult Read FOnGraphPaused Write FOnGraphPaused;

    { The graph is dropping samples, for quality control.
      A filter sends this event if it drops samples in response to a quality control
      message. It sends the event only when it adjusts the quality level, not for each
      sample that it drops. }
    Property OnGraphQualityChange: TNotifyEvent Read FOnGraphQualityChange Write FOnGraphQualityChange;

    { An audio device error occurred on an input pin.<br>
      <b>OccurWhen:</b> value from the TSNDDEV_ERR enumerated type, indicating how the device was being accessed when the failure occurred.<br>
      <b>ErrorCode:</b> value indicating the error returned from the sound device call. }
    Property OnGraphSNDDevInError: TOnGraphSNDDevError Read FOnGraphSNDDevInError Write FOnGraphSNDDevInError;

    { An audio device error occurred on an output pin.<br>
      <b>OccurWhen:</b> value from the TSNDDEV_ERR enumerated type, indicating how the device was being accessed when the failure occurred.<br>
      <b>ErrorCode:</b> value indicating the error returned from the sound device call. }
    Property OnGraphSNDDevOutError: TOnGraphSNDDevError Read FOnGraphSNDDevOutError Write FOnGraphSNDDevOutError;

    { A filter has completed frame stepping.
      The filter graph manager pauses the graph and passes the event to the application. }
    Property OnGraphStepComplete: TNotifyEvent Read FOnGraphStepComplete Write FOnGraphStepComplete;

    { A stream-control start command has taken effect.
      Filters send this event in response to the IAMStreamControl.StartAt method.
      This method specifies a reference time for a pin to begin streaming.
      When streaming does begin, the filter sends this event.<br>
      <b>PinSender</b> parameter specifies the pin that executes the start command.
      Depending on the implementation, it might not be the pin that
      received the StartAt call.<br>
      <b>Cookie</b> parameter is specified by the application in the StartAt method.
      This parameter enables the application to track multiple calls to the method. }
    Property OnGraphStreamControlStarted: TOnGraphStreamControl Read FOnGraphStreamControlStarted Write FOnGraphStreamControlStarted;

    { A stream-control start command has taken effect.
      Filters send this event in response to the IAMStreamControl.StopAt method.
      This method specifies a reference time for a pin to stop streaming.
      When streaming does halt, the filter sends this event.<br>
      <b>PinSender</b> parameter specifies the pin that executes the stop command.
      Depending on the implementation, it might not be the pin
      that received the StopAt call.<br>
      <b>Cookie</b> parameter is specified by the application in the StopAt method.
      This parameter enables the application to track multiple calls to the method. }
    Property OnGraphStreamControlStopped: TOnGraphStreamControl Read FOnGraphStreamControlStopped Write FOnGraphStreamControlStopped;

    { An error occurred in a stream, but the stream is still playing.<br>
      <b>Operation:</b> HRESULT of the operation that failed.<br>
      <b>Value:</b> LongWord value, generally zero. }
    Property OnGraphStreamErrorStillPlaying: TOnGraphStreamError Read FOnGraphStreamErrorStillPlaying Write FOnGraphStreamErrorStillPlaying;

    { A stream has stopped because of an error.<br>
      <b>Operation:</b> HRESULT of the operation that failed.<br>
      <b>Value:</b> LongWord value, generally zero. }
    Property OnGraphStreamErrorStopped: TOnGraphStreamError Read FOnGraphStreamErrorStopped Write FOnGraphStreamErrorStopped;

    { The user has terminated playback.<br>
      This event code signals that the user has terminated normal graph playback.
      for example, video renderers send this event if the user closes the video window.<br>
      After sending this event, the filter should reject all samples and not send
      any EC_REPAINT events, until the filter stops and is reset. }
    Property OnGraphUserAbort: TNotifyEvent Read FOnGraphUserAbort Write FOnGraphUserAbort;

    { The native video size has changed.<br>
      <b>width:</b> new width, in pixels.<br>
      <b>height:</b> new height, in pixels. }
    Property OnGraphVideoSizeChanged: TOnGraphVideoSizeChanged Read FOnGraphVideoSizeChanged Write FOnGraphVideoSizeChanged;

    { Sent by filter supporting timecode.<br>
      <b>From:</b> sending object.<br>
      <b>DeviceID:</b> device ID of the sending object }
    Property OnGraphTimeCodeAvailable: TOnGraphTimeCodeAvailable Read FOnGraphTimeCodeAvailable Write FOnGraphTimeCodeAvailable;

    { Sent by filter supporting IAMExtDevice.<br>
      <b>NewMode:</b> the new mode<br>
      <b>DeviceID:</b> the device ID of the sending object }
    Property OnGraphEXTDeviceModeChange: TOnGraphEXTDeviceModeChange Read FOnGraphEXTDeviceModeChange Write FOnGraphEXTDeviceModeChange;

    { The clock provider was disconnected.<br>
      KSProxy signals this event when the pin of a clock-providing filter is disconnected. }
    Property OnGraphClockUnset: TNotifyEvent Read FOnGraphClockUnset Write FOnGraphClockUnset;

    { Identifies the type of rendering mechanism the VMR is using to display video. }
    Property OnGraphVMRRenderDevice: TOnGraphVMRRenderDevice Read FOnGraphVMRRenderDevice Write FOnGraphVMRRenderDevice;

    { Signals that the current audio stream number changed for the main title.<br>
      The current audio stream can change automatically with a navigation command
      authored on the disc as well as through application control by using the IDvdControl2 interface.<br>
      <b>stream:</b> value indicating the new user audio stream number. Audio stream numbers
      range from 0 to 7. Stream $FFFFFFFF indicates that no stream is selected.<br>
      <b>lcid:</b> Language identifier.<br>
      <b>Lang:</b> Language string. }
    Property OnDVDAudioStreamChange: TOnDVDAudioStreamChange Read FOnDVDAudioStreamChange Write FOnDVDAudioStreamChange;

    { Deprecated, use @link(OnDVDCurrentHMSFTime) instead.<br>
      Signals the beginning of every video object unit (VOBU), a video segment
      which is 0.4 to 1.0 seconds in length.<br> }
    Property OnDVDCurrentTime: TOnDVDCurrentTime Read FOnDVDCurrentTime Write FOnDVDCurrentTime;

    { Indicates when the current title number changes.<br>
      Title numbers range from 1 to 99. This number indicates the TTN, which is
      the title number with respect to the whole disc, not the VTS_TTN which is
      the title number with respect to just a current VTS.<br>
      <b>Title:</b> value indicating the new title number. }
    Property OnDVDTitleChange: TOnDVDTitleChange Read FOnDVDTitleChange Write FOnDVDTitleChange;

    { Signals that the DVD player started playback of a new program in the
      DVD_DOMAIN_Title domain.<br>
      Only simple linear movies signal this event.<br>
      <b>chapter:</b> value indicating the new chapter (program) number. }
    Property OnDVDChapterStart: TOnDVDChapterStart Read FOnDVDChapterStart Write FOnDVDChapterStart;

    { Signals that either the number of available angles changed or that the
      current angle number changed.<br>
      Angle numbers range from 1 to 9. The current angle number can change
      automatically with a navigation command authored on the disc as well as
      through application control by using the IDvdControl2 interface.<br>
      <b>total:</b> value indicating the number of available angles. When the
      number of available angles is 1, the current video is not multiangle.<br>
      <b>current:</b> value indicating the current angle number. }
    Property OnDVDAngleChange: TOnDVDChange Read FOnDVDAngleChange Write FOnDVDAngleChange;

    { Signals that the available set of IDvdControl2 interface methods has changed.<br>
      <b>UOPS:</b> value representing a ULONG whose bits indicate which IDvdControl2
      commands the DVD disc explicitly disabled. }
    Property OnDVDValidUOPSChange: TOnDVDValidUOPSChange Read FOnDVDValidUOPSChange Write FOnDVDValidUOPSChange;

    { Signals that either the number of available buttons changed or that the
      currently selected button number changed.<br>
      This event can signal any of the available button numbers. These numbers
      do not always correspond to button numbers used for
      IDvdControl2.SelectAndActivateButton because that method can activate only
      a subset of buttons.<br>
      <b>total:</b> value indicating the number of available buttons.<br>
      <b>current:</b> value indicating the currently selected button number.
      Selected button number zero implies that no button is selected. }
    Property OnDVDButtonChange: TOnDVDChange Read FOnDVDButtonChange Write FOnDVDButtonChange;

    { Indicates that playback stopped as the result of a call to the
      IDvdControl2.PlayChaptersAutoStop method. }
    Property OnDVDChapterAutoStop: TNotifyEvent Read FOnDVDChapterAutoStop Write FOnDVDChapterAutoStop;

    { Signals the beginning of any still (PGC, Cell, or VOBU).
      All combinations of buttons and still are possible (buttons on with still
      on, buttons on with still off, button off with still on, button off with still off).<br>
      <b>NoButtonAvailable</b>: Boolean value indicating whether buttons are
      available. False indicates buttons are available so the IDvdControl2.StillOff
      method won't work. True indicates no buttons are available, so IDvdControl2.StillOff will work.<br>
      <b>seconds</b>: value indicating the number of seconds the still will last.
      $FFFFFFFF indicates an infinite still, meaning wait until the user presses
      a button or until the application calls IDvdControl2.StillOff. }
    Property OnDVDStillOn: TOnDVDStillOn Read FOnDVDStillOn Write FOnDVDStillOn;

    { Signals the end of any still (PGC, Cell, or VOBU).<br>
      This event indicates that any currently active still has been released. }
    Property OnDVDStillOff: TNotifyEvent Read FOnDVDStillOff Write FOnDVDStillOff;

    { Signals that the current subpicture stream number changed for the main title.<br>
      The subpicture can change automatically with a navigation command authored
      on disc as well as through application control using IDvdControl2.<br>
      <b>SubNum:</b> value indicating the new user subpicture stream number.
      Subpicture stream numbers range from 0 to 31. Stream $FFFFFFFF indicates
      that no stream is selected.<br>
      <b>lcid:</b> Language identifier.<br>
      <b>Lang:</b> Language string. }
    Property OnDVDSubpictureStreamChange: TOnDVDSubpictureStreamChange Read FOnDVDSubpictureStreamChange Write FOnDVDSubpictureStreamChange;

    { Signals that the DVD disc does not have a FP_PGC (First Play Program Chain)
      and that the DVD Navigator will not automatically load any PGC and start playback. }
    Property OnDVDNoFP_PGC: TNotifyEvent Read FOnDVDNoFP_PGC Write FOnDVDNoFP_PGC;

    { Signals that a rate change in the playback has been initiated.
      <b>rate:</b> indicate the new playback rate. rate < 0 indicates reverse playback
      mode. rate > 0 indicates forward playback mode. }
    Property OnDVDPlaybackRateChange: TOnDVDPlaybackRateChange Read FOnDVDPlaybackRateChange Write FOnDVDPlaybackRateChange;

    { Signals that the parental level of the authored content is about to change.<br>
      The DVD Navigator source filter does not currently support "on the fly"
      parental level changes in response to SetTmpPML commands on a DVD disc.<br>
      <b>level:</b> value representing the new parental level set in the player. }
    Property OnDVDParentalLevelChange: TOnDVDParentalLevelChange Read FOnDVDParentalLevelChange Write FOnDVDParentalLevelChange;

    { Indicates that playback has been stopped. The DVD Navigator has completed
      playback of the title or chapter and did not find any other branching
      instruction for subsequent playback. }
    Property OnDVDPlaybackStopped: TNotifyEvent Read FOnDVDPlaybackStopped Write FOnDVDPlaybackStopped;

    { Indicates whether an angle block is being played and angle changes can be performed.<br>
      Angle changes are not restricted to angle blocks and the manifestation of
      the angle change can be seen only in an angle block.<br>
      <b>available:</b> Boolean value that indicates if an angle block is being
      played back. False indicates that playback is not in an angle block and
      angles are not available, True indicates that an angle block is being played
      back and angle changes can be performed. }
    Property OnDVDAnglesAvailable: TOnDVDAnglesAvailable Read FOnDVDAnglesAvailable Write FOnDVDAnglesAvailable;

    { Indicates that the Navigator has finished playing the segment specified
      in a call to PlayPeriodInTitleAutoStop. }
    Property OnDVDPlayPeriodAutoStop: TNotifyEvent Read FOnDVDPlayPeriodAutoStop Write FOnDVDPlayPeriodAutoStop;

    { Signals that a menu button has been automatically activated per instructions
      on the disc. This occurs when a menu times out and the disc has specified a
      button to be automatically activated.<br>
      <b>Button</b>: value indicating the button that was activated. }
    Property OnDVDButtonAutoActivated: TOnDVDButtonAutoActivated Read FOnDVDButtonAutoActivated Write FOnDVDButtonAutoActivated;

    { Signals that a particular command has begun.<br>
      <b>CmdID:</b> The Command ID and the HRESULT return value. }
    Property OnDVDCMDStart: TOnDVDCMD Read FOnDVDCMDStart Write FOnDVDCMDStart;

    { Signals that a particular command has completed.<br>
      <b>CmdID</b> The Command ID and the completion result. }
    Property OnDVDCMDEnd: TOnDVDCMD Read FOnDVDCMDEnd Write FOnDVDCMDEnd;

    { Signals that a disc was ejected.<br>
      Playback automatically stops when a disc is ejected. The application does
      not have to take any special action in response to this event. }
    Property OnDVDDiscEjected: TNotifyEvent Read FOnDVDDiscEjected Write FOnDVDDiscEjected;

    { Signals that a disc was inserted into the drive.<br>
      Playback automatically begins when a disc is inserted. The application does
      not have to take any special action in response to this event. }
    Property OnDVDDiscInserted: TNotifyEvent Read FOnDVDDiscInserted Write FOnDVDDiscInserted;

    { Signals the current time, in DVD_HMSF_TIMECODE format, relative to the start
      of the title. This event is triggered at the beginning of every VOBU, which
      occurs every 0.4 to 1.0 seconds.<br>
      The TDVD_HMSF_TIMECODE format is intended to replace the old BCD format that
      is returned in OnDVDCurrentTime events. The HMSF timecodes are easier to
      work with. To have the Navigator send EC_DVD_CURRENT_HMSF_TIME events instead
      of EC_DVD_CURRENT_TIME events, an application must call
      IDvdControl2.SetOption(DVD_HMSF_TimeCodeEvents, TRUE). When this flag is set,
      the Navigator will also expect all time parameters in the IDvdControl2 and
      IDvdInfo2 methods to be passed as TDVD_HMSF_TIMECODEs.<br>
      <b>HMSFTimeCode:</b> HMS Time code structure.<br>
      <b>TimeCode:</b> old time format, do not use. }
    Property OnDVDCurrentHMSFTime: TOnDVDCurrentHMSFTime Read FOnDVDCurrentHMSFTime Write FOnDVDCurrentHMSFTime;

    { Indicates that the Navigator has either begun playing or finished playing karaoke data.<br>
      The DVD player signals this event whenever it changes domains.<br>
      <b>Played:</b> TRUE means that a karaoke track is being played and FALSE means
      that no karaoke data is being played. }
    Property OnDVDKaraokeMode: TOnDVDKaraokeMode Read FOnDVDKaraokeMode Write FOnDVDKaraokeMode;

    { Performing default initialization of a DVD disc. }
    Property OnDVDDomainFirstPlay: TNotifyEvent Read FOnDVDDomainFirstPlay Write FOnDVDDomainFirstPlay;

    { Displaying menus for whole disc. }
    Property OnDVDDomainVideoManagerMenu: TNotifyEvent Read FOnDVDDomainVideoManagerMenu Write FOnDVDDomainVideoManagerMenu;

    { Displaying menus for current title set. }
    Property OnDVDDomainVideoTitleSetMenu: TNotifyEvent Read FOnDVDDomainVideoTitleSetMenu Write FOnDVDDomainVideoTitleSetMenu;

    { Displaying the current title. }
    Property OnDVDDomainTitle: TNotifyEvent Read FOnDVDDomainTitle Write FOnDVDDomainTitle;

    { The DVD Navigator is in the DVD Stop domain. }
    Property OnDVDDomainStop: TNotifyEvent Read FOnDVDDomainStop Write FOnDVDDomainStop;

    { Something unexpected happened; perhaps content is authored incorrectly.
      Playback is stopped. }
    Property OnDVDErrorUnexpected: TNotifyEvent Read FOnDVDErrorUnexpected Write FOnDVDErrorUnexpected;

    { Key exchange for DVD copy protection failed. Playback is stopped. }
    Property OnDVDErrorCopyProtectFail: TNotifyEvent Read FOnDVDErrorCopyProtectFail Write FOnDVDErrorCopyProtectFail;

    { DVD-Video disc is authored incorrectly for specification version 1.x.
      Playback is stopped. }
    Property OnDVDErrorInvalidDVD1_0Disc: TNotifyEvent Read FOnDVDErrorInvalidDVD1_0Disc Write FOnDVDErrorInvalidDVD1_0Disc;

    { DVD-Video disc cannot be played because the disc is not authored to play in
      the system region. }
    Property OnDVDErrorInvalidDiscRegion: TNotifyEvent Read FOnDVDErrorInvalidDiscRegion Write FOnDVDErrorInvalidDiscRegion;

    { Player parental level is lower than the lowest parental level available in
      the DVD content. Playback is stopped. }
    Property OnDVDErrorLowParentalLevel: TNotifyEvent Read FOnDVDErrorLowParentalLevel Write FOnDVDErrorLowParentalLevel;

    { Macrovision® distribution failed. Playback stopped. }
    Property OnDVDErrorMacrovisionFail: TNotifyEvent Read FOnDVDErrorMacrovisionFail Write FOnDVDErrorMacrovisionFail;

    { No discs can be played because the system region does not match the decoder region. }
    Property OnDVDErrorIncompatibleSystemAndDecoderRegions: TNotifyEvent Read FOnDVDErrorIncompatibleSystemAndDecoderRegions Write FOnDVDErrorIncompatibleSystemAndDecoderRegions;

    { The disc cannot be played because the disc is not authored to be played in
      the decoder's region. }
    Property OnDVDErrorIncompatibleDiscAndDecoderRegions: TNotifyEvent Read FOnDVDErrorIncompatibleDiscAndDecoderRegions Write FOnDVDErrorIncompatibleDiscAndDecoderRegions;

    { DVD-Video disc is authored incorrectly. Playback can continue, but unexpected
      behavior might occur. }
    Property OnDVDWarningInvalidDVD1_0Disc: TNotifyEvent Read FOnDVDWarningInvalidDVD1_0Disc Write FOnDVDWarningInvalidDVD1_0Disc;

    { A decoder would not support the current format. Playback of a stream
      (audio, video or subpicture) might not function. }
    Property OnDVDWarningFormatNotSupported: TNotifyEvent Read FOnDVDWarningFormatNotSupported Write FOnDVDWarningFormatNotSupported;

    { The internal DVD navigation command processor attempted to process an illegal command. }
    Property OnDVDWarningIllegalNavCommand: TNotifyEvent Read FOnDVDWarningIllegalNavCommand Write FOnDVDWarningIllegalNavCommand;

    { File Open failed. }
    Property OnDVDWarningOpen: TNotifyEvent Read FOnDVDWarningOpen Write FOnDVDWarningOpen;

    { File Seek failed. }
    Property OnDVDWarningSeek: TNotifyEvent Read FOnDVDWarningSeek Write FOnDVDWarningSeek;

    { File Read failed. }
    Property OnDVDWarningRead: TNotifyEvent Read FOnDVDWarningRead Write FOnDVDWarningRead;

    { Notifys when a Moniker has been found for a MediaType of a Pin in the Graph.
      Return True to allow this Filter to be added, otherwise return False.
      Note: The Guid might not be the real Filter Class ID, but a Group ID.
      eg: Renderer Filters. }
    Property OnSelectedFilter: TOnSelectedFilter Read FOnSelectedFilter Write FOnSelectedFilter;

    { Notifys when a Filter has been created and is about to enter the Graph.
      Return True to allow this Filter to be added, otherwise return False. }
    Property OnCreatedFilter: TOnCreatedFilter Read FOnCreatedFilter Write FOnCreatedFilter;

    { Notifys about a Pin that couldn't be Rendered. Return True to try it again,
      otherwise return False. }
    Property OnUnableToRender: TOnUnableToRender Read FOnUnableToRender Write FOnUnableToRender;
  End;


  // *****************************************************************************
  // TVMROptions
  // *****************************************************************************

  { @exclude }
  TVideoWindow = Class;

  { See VRMOptions.<br> }
  TVMRVideoMode = (VmrWindowed, VmrWindowless, VmrRenderless);

  { Video Mixer Renderer property editor. }
  TVMROptions = Class(TPersistent)
  Private
    FOwner: TVideoWindow;
    FStreams: Cardinal;
    FPreferences: TVMRPreferences;
    FMode: TVMRVideoMode;
    FKeepAspectRatio: Boolean;
    Procedure SetStreams(Streams: Cardinal);
    Procedure SetPreferences(Preferences: TVMRPreferences);
    Procedure SetMode(AMode: TVMRVideoMode);
    Procedure SetKeepAspectRatio(Keep: Boolean);
  Public
    { Constructor method. }
    Constructor Create(AOwner: TVideoWindow);
  Published
    { Windowed or WindowLess }
    Property Mode: TVMRVideoMode Read FMode Write SetMode;
    { Sets the number of streams to be mixed. }
    Property Streams: Cardinal Read FStreams Write SetStreams Default 4;
    { Sets various application preferences related to video rendering. }
    Property Preferences: TVMRPreferences Read FPreferences Write SetPreferences Default [VpForceMixer];
    { Keep Aspect Ration on the video window. }
    Property KeepAspectRatio: Boolean Read FKeepAspectRatio Write SetKeepAspectRatio Default True;
  End;

  // *****************************************************************************
  // TVideoWindow
  // *****************************************************************************

  TAbstractAllocator = Class(TInterfacedObject)
    Constructor Create(Out Hr: HResult; Wnd: THandle; D3d: IDirect3D9 = Nil; D3dd: IDirect3DDevice9 = Nil); Virtual; Abstract;
  End;

  TAbstractAllocatorClass = Class Of TAbstractAllocator;

  { Manage a Video Renderer or a Video Mixer Renderer (VMR) Filter to display
    a video in your application. }
  TVideoWindow = Class(TCustomControl, IFilter, IEvent)
  Private
    FMode: TVideoMode;
    FVMROptions: TVMROptions;
    FBaseFilter: IBaseFilter;
    FVideoWindow: IVideoWindow; // VMR Windowed & Normal
    FWindowLess: IVMRWindowlessControl9; // VMR Windowsless

    FFullScreen: Boolean;
    FFilterGraph: TFilterGraph;
    FWindowStyle: LongWord;
    FWindowStyleEx: LongWord;
    FTopMost: Boolean;
    FIsFullScreen: Boolean;
    FOnPaint: TNotifyEvent;
    FKeepAspectRatio: Boolean;
    FAllocatorClass: TAbstractAllocatorClass;
    FCurrentAllocator: TAbstractAllocator;
    FRenderLessUserID: Cardinal;
    Procedure SetVideoMode(AMode: TVideoMode);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
    Procedure SetFullScreen(Value: Boolean);
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
    Procedure GraphEvent(Event, Param1, Param2: Integer);
    Function GetName: String;
    Function GetVideoHandle: THandle;
    Procedure ControlEvent(Event: TControlEvent; Param: Integer = 0);
    Procedure SetTopMost(TopMost: Boolean);
    Function GetVisible: Boolean;
    Procedure SetVisible(Vis: Boolean);
  Protected
    FIsVideoWindowOwner: Boolean;
    { @exclude }
    Procedure Loaded; Override;
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
    { @exclude }
    Procedure Resize; Override;
    { @exclude }
    Procedure ConstrainedResize(Var MinWidth, MinHeight, MaxWidth, MaxHeight: Integer); Override;
    { @exclude }
    Function GetFilter: IBaseFilter;
    { @exclude }
    Procedure WndProc(Var Message: TMessage); Override;
    { @exclude }
    Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MouseMove(Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure Paint; Override;
  Public
    { @exclude }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;
    { Constructor. }
    Constructor Create(AOwner: TComponent); Override;
    { Destructor. }
    Destructor Destroy; Override;
    { Check if the Video Mixer Renderer is available (Windows XP). }
    Class Function CheckVMR: Boolean;
    { Retrieve the current bitmap, only in WindowLess VMR Mode. }
    Function VMRGetBitmap(Stream: TStream): Boolean;
    Function CheckInputPinsConnected: Boolean;
    Procedure SetAllocator(Allocator: TAbstractAllocatorClass; UserID: Cardinal);
    Property IsVideoWindowOwner: Boolean Read FIsVideoWindowOwner Write FIsVideoWindowOwner;
  Published
    { VMR/WindowsLess Mode only. }
    Property OnPaint: TNotifyEvent Read FOnPaint Write FOnPaint;
    { The video Window stay on Top in FullScreen Mode. }
    Property FullScreenTopMost: Boolean Read FTopMost Write SetTopMost Default False;
    { Video Mode, you can use Normal mode or VMR mode (VMR is only available on WindowsXP). }
    Property Mode: TVideoMode Read FMode Write SetVideoMode Default VmNormal;
    { The @link(TFilterGraph) component }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;
    { Return the Handle where the video is displayed. }
    Property VideoHandle: THandle Read GetVideoHandle;
    { Video Mixer Renderer property editor. }
    Property VMROptions: TVMROptions Read FVMROptions Write FVMROptions;
    { Set the full screen mode. }
    Property FullScreen: Boolean Read FFullScreen Write SetFullScreen Default False;
    { Common properties & Events }
    { @exclude }
    Property Color; { @exclude }
    Property Visible: Boolean Read GetVisible Write SetVisible Default True; { @exclude }
    Property ShowHint; { @exclude }
    Property Anchors; { @exclude }
    Property Canvas; { @exclude }
    Property PopupMenu; { @exclude }
    Property Align; { @exclude }
    Property TabStop Default True; { @exclude }
    Property OnEnter; { @exclude }
    Property OnExit; { @exclude }
    Property OnKeyDown; { @exclude }
    Property OnKeyPress; { @exclude }
    Property OnKeyUp; { @exclude }
    Property OnCanResize; { @exclude }
    Property OnClick; { @exclude }
    Property OnConstrainedResize; { @exclude }
    Property OnDblClick; { @exclude }
    Property OnMouseDown; { @exclude }
    Property OnMouseMove; { @exclude }
    Property OnMouseUp; { @exclude }
    Property OnMouseWheel; { @exclude }
    Property OnMouseWheelDown; { @exclude }
    Property OnMouseWheelUp; { @exclude }
    Property OnResize;
  End;

  // ******************************************************************************
  //
  // TFilterSampleGrabber declaration
  // description: Sample Grabber Wrapper Filter
  //
  // ******************************************************************************
  { @exclude }
  TSampleGrabber = Class;

  { This class is designed make a snapshoot of Video or Audio Datas.
    WARNING: There is know problems with some DIVX movies, so use RGB32 Media Type
    instead of RBG24. }
  TSampleGrabber = Class(TComponent, IFilter, ISampleGrabberCB)
  Private
    FOnBuffer: TOnBuffer;
    FBaseFilter: IBaseFilter;
    FFilterGraph: TFilterGraph;
    FMediaType: TMediaType;
    // [pjh, 2003-07-14] delete BMPInfo field
    // BMPInfo : PBitmapInfo;
    FCriticalSection: TCriticalSection;
    Function GetFilter: IBaseFilter;
    Function GetName: String;
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
    Function SampleCB(SampleTime: Double; PSample: IMediaSample): HResult; Stdcall;
    Function BufferCB(SampleTime: Double; PBuffer: PByte; BufferLen: Longint): HResult; Stdcall;
  Protected
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
  Public
    { ISampleGrabber Interface to control the SampleGrabber Filter.
      The FilterGraph must be active. }
    SampleGrabber: ISampleGrabber;
    { The Input Pin.
      The FilterGraph must be active. }
    InPutPin: IPin;
    { The Output Pin.
      The FilterGraph must be active. }
    OutPutPin: IPin;
    { Constructor method. }
    Constructor Create(AOwner: TComponent); Override;
    { Destructor method. }
    Destructor Destroy; Override;
    { Configure the filter to cature the specified MediaType.
      This method disconnect the Input pin if connected.
      The FilterGraph must be active. }
    Procedure UpdateMediaType;
    { @exclude }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;
    { Configure the MediaType according to the Source MediaType to be compatible with the BMP format.
      if Source = nil then this method use the default value to set the resolution: 1..32.
      The MediaType is auto configured to RGB24. }
    Procedure SetBMPCompatible(Source: PAMMediaType; SetDefault: Cardinal);
    { This method read the buffer received in the OnBuffer event and paint the bitmap. }
    Function GetBitmap(Bitmap: TBitmap; Buffer: Pointer; BufferLen: Integer): Boolean; Overload;
    { This method read the current buffer from the Sample Grabber Filter and paint the bitmap. }
    Function GetBitmap(Bitmap: TBitmap): Boolean; Overload;
    { This method check if the Sample Grabber Filter is correctly registered on the system. }
    Class Function CheckFilter: Boolean;
  Published
    { Receive the Buffer from the Sample Grabber Filter. }
    Property OnBuffer: TOnBuffer Read FOnBuffer Write FOnBuffer;
    { The filter must connected to a TFilterGraph component. }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;
    { The media type to capture. You can capture audio or video data. }
    Property MediaType: TMediaType Read FMediaType Write FMediaType;
  End;

  // *****************************************************************************
  // TFilter
  // *****************************************************************************

  { This component is an easy way to add a specific filter to a filter graph.
    You can retrieve an interface using the <b>as</b> operator whith D6 :) }
  TFilter = Class(TComponent, IFilter)
  Private
    FFilterGraph: TFilterGraph;
    FBaseFilter: TBaseFilter;
    FFilter: IBaseFilter;
    Function GetFilter: IBaseFilter;
    Function GetName: String;
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
  Protected
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
  Public
    { Constructor method. }
    Constructor Create(AOwner: TComponent); Override;
    { Destructor method. }
    Destructor Destroy; Override;
    { Retrieve a filter interface. }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;
  Published
    { This is the Filter Editor . }
    Property BaseFilter: TBaseFilter Read FBaseFilter Write FBaseFilter;
    { The filter must be connected to a TFilterGraph component. }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;
  End;

  // *****************************************************************************
  // TASFWriter
  // *****************************************************************************

  { This component is designed to create a ASF file or to stream over a network. }
  TASFWriter = Class(TComponent, IFilter)
  Private
    FFilterGraph: TFilterGraph;
    FFilter: IBaseFilter;
    FPort: Cardinal;
    FMaxUsers: Cardinal;
    FProfile: TWMPofiles8;
    FFileName: UnicodeString;
    FAutoIndex: Boolean;
    FMultiPass: Boolean;
    FDontCompress: Boolean;
    Function GetProfile: TWMPofiles8;
    Procedure SetProfile(Profile: TWMPofiles8);
    Function GetFileName: String;
    Procedure SetFileName(FileName: String);
    Function GetFilter: IBaseFilter;
    Function GetName: String;
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
  Protected
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
  Public
    { Sink configuration. }
    WriterAdvanced2: IWMWriterAdvanced2;
    { NetWork streaming configuration. }
    WriterNetworkSink: IWMWriterNetworkSink;
    { The Audio Input Pin. }
    AudioInput: IPin;
    { The Video Input Pin. }
    VideoInput: IPin;
    { Audio Input configuration. }
    AudioStreamConfig: IAMStreamConfig;
    { VideoInput configuration }
    VideoStreamConfig: IAMStreamConfig;
    { Destructor method. }
    Constructor Create(AOwner: TComponent); Override;
    Destructor Destroy; Override;
    { @exclude }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;
  Published
    { The filter must be connected to a TFilterGraph component. }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;
    { Windows media profile to use. }
    Property Profile: TWMPofiles8 Read GetProfile Write SetProfile;
    { Destination file name to write the compressed file. }
    Property FileName: String Read GetFileName Write SetFileName;
    { Port number to stream. }
    Property Port: DWORD Read FPort Write FPort;
    { The max number of connections. }
    Property MaxUsers: DWORD Read FMaxUsers Write FMaxUsers;
    Property AutoIndex: Boolean Read FAutoIndex Write FAutoIndex Default True;
    Property MultiPass: Boolean Read FMultiPass Write FMultiPass Default False;
    Property DontCompress: Boolean Read FDontCompress Write FDontCompress Default False;

  End;

  // *****************************************************************************
  // TDSTrackBar
  // *****************************************************************************
  { @exclude }
  TTimerEvent = Procedure(Sender: TObject; CurrentPos, StopPos: Cardinal) Of Object;

  { This control implement a seek bar for a media-player application.
    The seek bar is implemented as a TTrackbar control. }
  TDSTrackBar = Class(TTrackBar, IEvent)
  Private
    FFilterGraph: TFilterGraph;
    FMediaSeeking: IMediaSeeking;
    FWindowHandle: HWND;
    FInterval: Cardinal;
    FOnTimer: TTimerEvent;
    FEnabled: Boolean;
    FMouseDown: Boolean;
    Procedure UpdateTimer;
    Procedure SetTimerEnabled(Value: Boolean);
    Procedure SetInterval(Value: Cardinal);
    Procedure SetOnTimer(Value: TTimerEvent);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
    Procedure GraphEvent(Event, Param1, Param2: Integer);
    Procedure ControlEvent(Event: TControlEvent; Param: Integer = 0);
    Procedure TimerWndProc(Var Msg: TMessage);
    Property TimerEnabled: Boolean Read FEnabled Write SetTimerEnabled;
  Protected
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
    { @exclude }
    Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure Timer; Dynamic;
  Public
    { constructor method. }
    Constructor Create(AOwner: TComponent); Override;
    { destructor method. }
    Destructor Destroy; Override;
  Published
    { Select the filtergraph to seek. }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;
    { Select the time interval in miliseconds. default = 1000 mls. }
    Property TimerInterval: Cardinal Read FInterval Write SetInterval Default 1000;
    { OnTimer event, you can retrieve the current and stop positions here. }
    Property OnTimer: TTimerEvent Read FOnTimer Write SetOnTimer;
  End;

  { @exclude }
  TDSVideoWindowEx2 = Class;

  // *****************************************************************************
  // TColorControl
  // *****************************************************************************

  { Set and Get ColorControls from DSVideoWindowEx's OverlayMixer.
    This is Hardware based so your graphic card has to support it.
    Check DSVideoWindowEx's Capabilities if your card support a given
    colorcontrol. }
  TColorControl = Class(TPersistent)
  Private
    FBrightness: Integer;
    FContrast: Integer;
    FHue: Integer;
    FSaturation: Integer;
    FSharpness: Integer;
    FGamma: Integer;
    FUtilColor: Boolean;
    FDefault: TDDColorControl;
  Protected
    { Protected declarations }
    { @exclude }
    FOwner: TDSVideoWindowEx2;
    { @exclude }
    Procedure SetBrightness(Value: Integer);
    { @exclude }
    Procedure SetContrast(Value: Integer);
    { @exclude }
    Procedure SetHue(Value: Integer);
    { @exclude }
    Procedure SetSaturation(Value: Integer);
    { @exclude }
    Procedure SetSharpness(Value: Integer);
    { @exclude }
    Procedure SetGamma(Value: Integer);
    { @exclude }
    Procedure SetUtilColor(Value: Boolean);

    { @exclude }
    Function GetBrightness: Integer;
    { @exclude }
    Function GetContrast: Integer;
    { @exclude }
    Function GetHue: Integer;
    { @exclude }
    Function GetSaturation: Integer;
    { @exclude }
    Function GetSharpness: Integer;
    { @exclude }
    Function GetGamma: Integer;
    { @exclude }
    Function GetUtilColor: Boolean;
    { @exclude }
    Procedure ReadDefault;
    { @exclude }
    Procedure UpdateColorControls;
    { @exclude }
    Procedure GetColorControls;
  Public
    { Public declarations }
    { @exclude }
    Constructor Create(AOwner: TDSVideoWindowEx2); Virtual;
    { Restore the colorcontrols to there (Default) values.
      Default is the value the colorcontrol hat, just after we initilized the overlay Mixer. }
    Procedure RestoreDefault;
  Published
    { The Brightness property defines the luminance intensity, in IRE units, multiplied by 100.
      The possible range is from 0 to 10,000 with a default of 750. }
    Property Brightness: Integer Read GetBrightness Write SetBrightness;

    { The Contrast property defines the relative difference between higher and lower luminance values, in IRE units, multiplied by 100.
      The possible range is from 0 to 20,000 with a default value of 10,000. }
    Property Contrast: Integer Read GetContrast Write SetContrast;

    { The Hue property defines the phase relationship, in degrees, of the chrominance components.
      The possible range is from -180 to 180, with a default of 0. }
    Property Hue: Integer Read GetHue Write SetHue;

    { The Saturation property defines the color intensity, in IRE units, multiplied by 100.
      The possible range is 0 to 20,000, with a default value of 10,000. }
    Property Saturation: Integer Read GetSaturation Write SetSaturation;

    { The Sharpness property defines the sharpness, in arbitrary units, of an image.
      The possible range is 0 to 10, with a default value of 5. }
    Property Sharpness: Integer Read GetSharpness Write SetSharpness;

    { The Gamma property defines the amount, in gamma units, of gamma correction applied to the luminance values.
      The possible range is from 1 to 500, with a default of 1. }
    Property Gamma: Integer Read GetGamma Write SetGamma;

    { The ColorEnable property defines whether color is utilized or not.
      Color is used if this property is 1. Color is not used if this property is 0. The default value is 1. }
    Property ColorEnable: Boolean Read GetUtilColor Write SetUtilColor;
  End;

  // *****************************************************************************
  // TDSVideoWindowEx2Caps
  // *****************************************************************************

  { Check capability of DSVideoWindowEx. }
  TDSVideoWindowEx2Caps = Class(TPersistent)
  Protected
    { Protected declarations }
    Owner: TDSVideoWindowEx2;
    Function GetCanOverlay: Boolean;
    Function GetCanControlBrigtness: Boolean;
    Function GetCanControlContrast: Boolean;
    Function GetCanControlHue: Boolean;
    Function GetCanControlSaturation: Boolean;
    Function GetCanControlSharpness: Boolean;
    Function GetCanControlGamma: Boolean;
    Function GetCanControlUtilizedColor: Boolean;
  Public
    { Public declarations }
    { @exclude }
    Constructor Create(AOwner: TDSVideoWindowEx2); Virtual;
  Published
    { if CanOverlayGraphics return true, you draw on DSVideoWindowEx's canvas and the
      graphic will bee ontop of the Video. }
    Property CanOverlayGraphic: Boolean Read GetCanOverlay;

    { Repport if you can control Brightness on the video overlay }
    Property CanControlBrigtness: Boolean Read GetCanControlBrigtness;
    { Repport if you can control Contrast on the video overlay }
    Property CanControlContrast: Boolean Read GetCanControlContrast;
    { Repport if you can control Hue on the video overlay }
    Property CanControlHue: Boolean Read GetCanControlHue;
    { Repport if you can control Saturation on the video overlay }
    Property CanControlSaturation: Boolean Read GetCanControlSaturation;
    { Repport if you can control Sharpness on the video overlay }
    Property CanControlSharpness: Boolean Read GetCanControlSharpness;
    { Repport if you can control Gamma on the video overlay }
    Property CanControlGamma: Boolean Read GetCanControlGamma;
    { Repport if you can control ColorEnabled on the video overlay }
    Property CanControlColorEnabled: Boolean Read GetCanControlUtilizedColor;
  End;

  // *****************************************************************************
  // TOverlayCallback
  // *****************************************************************************

  { @exclude }
  TOverlayCallback = Class(TInterfacedObject, IDDrawExclModeVideoCallBack)
    AOwner: TObject;
    Constructor Create(Owner: TObject); Virtual;
    Function OnUpdateOverlay(BBefore: BOOL; DwFlags: DWORD; BOldVisible: BOOL; Var PrcOldSrc, PrcOldDest: TRECT; BNewVisible: BOOL; Var PrcNewSrc, PrcNewDest: TRECT): HRESULT; Stdcall;
    Function OnUpdateColorKey(Var PKey: TCOLORKEY; DwColor: DWORD): HRESULT; Stdcall;
    Function OnUpdateSize(DwWidth, DwHeight, DwARWidth, DwARHeight: DWORD): HRESULT; Stdcall;
  End;

  // *****************************************************************************
  // TDSVideoWindowEx2
  // *****************************************************************************

  { @exclude }
  TRatioModes = (RmStretched, RmLetterBox, RmCrop);

  { @exclude }
  TOverlayVisibleEvent = Procedure(Sender: TObject; Visible: Boolean) Of Object;

  { @exclude }
  TCursorVisibleEvent = Procedure(Sender: TObject; Visible: Boolean) Of Object;

  { A alternative to the regular Video Renderer (TVideoWindow), that give a easy way to overlay graphics
    onto your video in your application. }
  TDSVideoWindowEx2 = Class(TCustomControl, IFilter, IEvent)
  Private
    FVideoWindow: IVideoWindow;
    FFilterGraph: TFilterGraph;
    FBaseFilter: IBaseFilter;
    FOverlayMixer: IBaseFilter;
    FVideoRenderer: IBaseFilter;
    FDDXM: IDDrawExclModeVideo;
    FFullScreen: Boolean;
    FTopMost: Boolean;
    FColorKey: TColor;
    FWindowStyle: LongWord;
    FWindowStyleEx: LongWord;
    FVideoRect: TRect;
    FOnPaint: TNotifyEvent;
    FOnColorKey: TNotifyEvent;
    FOnCursorVisible: TCursorVisibleEvent;
    FOnOverlay: TOverlayVisibleEvent;
    FColorControl: TColorControl;
    FCaps: TDSVideoWindowEx2Caps;
    FZoom: Integer;
    FAspectMode: TRatioModes;
    FNoScreenSaver: Boolean;
    FIdleCursor: Integer;
    FMonitor: TMonitor;
    FFullscreenControl: TForm;
    GraphWasUpdatet: Boolean;
    FOldParent: TWinControl;
    OverlayCallback: TOverlayCallback;
    GraphBuildOK: Boolean;
    FVideoWindowHandle: HWND;
    LMousePos: TPoint;
    LCursorMov: DWord;
    RememberCursor: TCursor;
    IsHidden: Bool;
    FOverlayVisible: Boolean;
    OldDesktopColor: Longint;
    OldDesktopPic: String;
    FDesktopPlay: Boolean;
    Procedure NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
    Procedure GraphEvent(Event, Param1, Param2: Integer);
    Function GetName: String;
    Procedure ControlEvent(Event: TControlEvent; Param: Integer = 0);
    Procedure SetFilterGraph(AFilterGraph: TFilterGraph);
    Procedure SetTopMost(TopMost: Boolean);
    Procedure SetZoom(Value: Integer);
    Function UpdateGraph: HResult;
    Function GetVideoInfo: HResult;
    Procedure SetAspectMode(Value: TRatioModes);
    Procedure FullScreenCloseQuery(Sender: TObject; Var CanClose: Boolean);
    Procedure SetVideoZOrder;
  Protected
    FIsVideoWindowOwner: Boolean;
    { @exclude }
    Function GetFilter: IBaseFilter;
    { @exclude }
    Procedure Resize; Override;
    { @exclude }
    Procedure Loaded; Override;
    { @exclude }
    Procedure Notification(AComponent: TComponent; Operation: TOperation); Override;
    { @exclude }
    Procedure WndProc(Var Message: TMessage); Override;
    { @exclude }
    Procedure Paint; Override;
    { @exclude }
    Procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MouseMove(Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); Override;
    { @exclude }
    Procedure MyIdleHandler(Sender: TObject; Var Done: Boolean);
    { @exclude }
    Procedure RefreshVideoWindow;
  Public
    { constructor method. }
    Constructor Create(AOwner: TComponent); Override;
    { destructor method. }
    Destructor Destroy; Override;

    { @exclude }
    Function QueryInterface(Const IID: TGUID; Out Obj): HResult; Override; Stdcall;

    { Clear the graphic ontop of DSVideoWindowEx. }
    Procedure ClearBack;

    { Use your Desktop as the Video renderer.
      The video will display as a "wallpaper" on your Desktop }
    Procedure StartDesktopPlayback; Overload;

    { Use your Desktop as the Video renderer.
      The video will display as a "wallpaper" on your Desktop on the
      specifyed monitor }
    Procedure StartDesktopPlayBack(OnMonitor: TMonitor); Overload;

    { Return to normal window playback from Fullscreen or Desktop mode. }
    Procedure NormalPlayback;

    { Start playback in fullscreen }
    Procedure StartFullScreen; Overload;

    { Start playback in fullscreen on specifyed Monitor }
    Procedure StartFullScreen(OnMonitor: TMonitor); Overload;

    { repporting if you are currently playing in fullscreen. }
    Property FullScreen: Boolean Read FFullScreen;

    { repporting if you are currently playing on the Desktop. }
    Property DesktopPlayback: Boolean Read FDesktopPlay;
    { @inherited }
    Property Canvas;

    { The Colorkey is the color that the Overlay Mixer Filter used by DSVideoWindowEx sees
      as transparent, when you draw ontop of the movie always set the canvass brush
      color to this color or set the style to bsclear.
      Note: The colors returned through this method vary depending on the current display mode.
      if the colors are 8-bit palettized, they will be bright system colors (such as magenta).
      if the display is in a true-color mode, they will be shades of black. }
    Property ColorKey: TColor Read FColorKey;

    { @link(TDSVideoWindowEx2Caps) }
    Property Capabilities: TDSVideoWindowEx2Caps Read FCaps;

    { Check this property to see if the overlay is visible when you draw on DSVideoWindowEx's
      canvas, if it is visible you should set your brush color to the same as the VideoColor and
      if not set your brush to the same color as DSVideoWindowEx color. }
    Property OverlayVisible: Boolean Read FOverlayVisible;
    Property IsVideoWindowOwner: Boolean Read FIsVideoWindowOwner Write FIsVideoWindowOwner;
  Published
    { The AspectRatio property sets the aspect ratio correction mode for window resizing.
      rmSTRETCHED : No aspect ratio correction.
      rmLETTERBOX : Put the video in letterbox format. Paint background color in the
      excess region  so the video is not distorted.
      rmCROP      : Crop the video to the correct aspect ratio. }
    Property AspectRatio: TRatioModes Read FAspectMode Write SetAspectMode;

    { Set the amounts of milliseconds befor the cursor is hidden, if it is not moved.
      Setting the value to 0 will disable this feature. }
    Property AutoHideCursor: Integer Read FIdleCursor Write FIdleCursor;

    { Specify a Zoom factor from 0 to 99 procent. }
    Property DigitalZoom: Integer Read FZoom Write SetZoom;

    { The @link(TFilterGraph) component }
    Property FilterGraph: TFilterGraph Read FFilterGraph Write SetFilterGraph;

    { Select if the VideoWindow it topmost or not. }
    Property FullScreenTopMost: Boolean Read FTopMost Write SetTopMost Default False;

    { Event to tell the main application that the Colorkey has changed.
      Note: if you have controls placed ontop of your VideoWindow that need to act as
      transparent, set there color to the same as the Colorkey. }
    Property OnColorKeyChanged: TNotifyEvent Read FOnColorKey Write FOnColorKey;

    { @link(TColorControl) }
    Property ColorControl: TColorControl Read FColorControl Write FColorControl;

    { Setting this to true will prevent the screen to go into screensaver or powerdown. }
    Property NoScreenSaver: Boolean Read FNoScreenSaver Write FNoScreenSaver;

    { This event accure when the Visible state of the overlay changes
      Note: Most used to hide the video in the player window when going to
      DesktopPlayback. }
    Property OnOverlayVisible: TOverlayVisibleEvent Read FOnOverlay Write FOnOverlay;

    Property OnPaint: TNotifyevent Read FOnPaint Write FOnPaint;

    { This event accure when the cursor change from showing to hiding or from hiding to showing. }
    Property OnCursorShowHide: TCursorVisibleEvent Read FOnCursorVisible Write FOnCursorVisible;

    Property Color; { @exclude }
    Property Visible; { @exclude }
    Property ShowHint; { @exclude }
    Property Anchors; { @exclude }
    Property PopupMenu; { @exclude }
    Property Align; { @exclude }
    Property TabStop Default True; { @exclude }
    Property OnEnter; { @exclude }
    Property OnExit; { @exclude }
    Property OnKeyDown; { @exclude }
    Property OnKeyPress; { @exclude }
    Property OnKeyUp; { @exclude }
    Property OnCanResize; { @exclude }
    Property OnClick; { @exclude }
    Property OnConstrainedResize; { @exclude }
    Property OnDblClick; { @exclude }
    Property OnMouseDown; { @exclude }
    Property OnMouseMove; { @exclude }
    Property OnMouseUp; { @exclude }
    Property OnMouseWheel; { @exclude }
    Property OnMouseWheelDown; { @exclude }
    Property OnMouseWheelUp; { @exclude }
    Property OnResize;
  End;

  /// /////////////////////////////////////////////////////////////////////////////
  //
  // TVMRBitmap Class
  //
  /// /////////////////////////////////////////////////////////////////////////////
Type

  { vmrbDisable: Disable the alpha bitmap.
    vmrbSrcColorKey: Enable ColorKey.
    vmrbSrcRect: Indicates that the Dest property is valid and specifies
    a sub-rectangle of the original image to be blended. }

  TVMRBitmapOption = (VmrbDisable, VmrbSrcColorKey, VmrbSrcRect);
  TVMRBitmapOptions = Set Of TVMRBitmapOption;

  TVMRBitmap = Class
  Private
    FVideoWindow: TVideoWindow;
    FCanvas: TCanvas;
    FVMRALPHABITMAP: TVMR9ALPHABITMAP;
    FOptions: TVMRBitmapOptions;
    FBMPOld: HBITMAP;
    Procedure SetOptions(Options: TVMRBitmapOptions);
    Procedure ResetBitmap;
    Procedure SetAlpha(Const Value: Single);
    Procedure SetColorKey(Const Value: COLORREF);
    Procedure SetDest(Const Value: TVMR9NormalizedRect);
    Procedure SetDestBottom(Const Value: Single);
    Procedure SetDestLeft(Const Value: Single);
    Procedure SetDestRight(Const Value: Single);
    Procedure SetDestTop(Const Value: Single);
    Procedure SetSource(Const Value: TRect);
    Function GetAlpha: Single;
    Function GetColorKey: COLORREF;
    Function GetDest: TVMR9NormalizedRect;
    Function GetDestBottom: Single;
    Function GetDestLeft: Single;
    Function GetDestRight: Single;
    Function GetDestTop: Single;
    Function GetSource: TRect;
  Public
    // Contructor, set the video Window where the bitmat must be paint.
    Constructor Create(VideoWindow: TVideoWindow);
    // Cleanup
    Destructor Destroy; Override;
    // Load a Bitmap from a TBitmap class.
    Procedure LoadBitmap(Bitmap: TBitmap);
    // Initialize with an empty bitmap.
    Procedure LoadEmptyBitmap(Width, Height: Integer; PixelFormat: TPixelFormat; Color: TColor);
    // Draw the bitmap to the Video Window.
    Procedure Draw;
    // Draw the bitmap on a particular position.
    Procedure DrawTo(Left, Top, Right, Bottom, Alpha: Single; DoUpdate: Boolean = False);
    // update the video window with the current bitmap
    Procedure Update;
    // Uses this property to draw on the internal bitmap.
    Property Canvas: TCanvas Read FCanvas Write FCanvas;
    // Change Alpha Blending
    Property Alpha: Single Read GetAlpha Write SetAlpha;
    // set the source rectangle
    Property Source: TRect Read GetSource Write SetSource;
    // Destination Left
    Property DestLeft: Single Read GetDestLeft Write SetDestLeft;
    // Destination Top
    Property DestTop: Single Read GetDestTop Write SetDestTop;
    // Destination Right
    Property DestRight: Single Read GetDestRight Write SetDestRight;
    // Destination Bottom
    Property DestBottom: Single Read GetDestBottom Write SetDestBottom;
    // Destination
    Property Dest: TVMR9NormalizedRect Read GetDest Write SetDest;
    // Set the color key for transparency.
    Property ColorKey: COLORREF Read GetColorKey Write SetColorKey;
    // VMR Bitmap Options.
    Property Options: TVMRBitmapOptions Read FOptions Write SetOptions;
  End;

Implementation

Uses ComObj;

Const
  CLSID_FilterGraphCallback: TGUID = '{C7CAA944-C191-4AB1-ABA7-D8B40EF4D5B2}';

  // *****************************************************************************
  // TFilterGraph
  // *****************************************************************************

Constructor TFilterGraph.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FHandle := AllocateHWnd(WndProc);
  FVolume := 10000;
  FBalance := 0;
  FRate := 1.0;
  FLinearVolume := True;
End;

Destructor TFilterGraph.Destroy;
Begin
  SetActive(False);
  DeallocateHWnd(FHandle);
  Inherited Destroy;
End;

Procedure TFilterGraph.SetGraphMode(Mode: TGraphMode);
Var
  WasActive: Boolean;
Begin
  If FMode = Mode Then Exit;
  WasActive := Active;
  Active := False;
  FMode := Mode;
  Active := WasActive;
End;

Procedure TFilterGraph.SetActive(Activate: Boolean);
Var
  Obj: IObjectWithSite;
  Fgcb: IAMFilterGraphCallback;
  Gbcb: IAMGraphBuilderCallback;
Const
  IID_IObjectWithSite: TGuid = '{FC4801A3-2BA9-11CF-A229-00AA003D7352}';
Begin
  If Activate = FActive Then Exit;
  Case Activate Of
    True: Begin
        Case FMode Of
          GmNormal: CoCreateInstance(CLSID_FilterGraph, Nil, CLSCTX_INPROC_SERVER, IID_IFilterGraph2, FFilterGraph);
          GmCapture: Begin
              CoCreateInstance(CLSID_CaptureGraphBuilder2, Nil, CLSCTX_INPROC_SERVER, IID_ICaptureGraphBuilder2, FCaptureGraph);
              CoCreateInstance(CLSID_FilterGraph, Nil, CLSCTX_INPROC_SERVER, IID_IFilterGraph2, FFilterGraph);
              FCaptureGraph.SetFiltergraph(IGraphBuilder(FFilterGraph));
            End;
          GmDVD: Begin
              CoCreateInstance(CLSID_DvdGraphBuilder, Nil, CLSCTX_INPROC_SERVER, IID_IDvdGraphBuilder, FDvdGraph);
              FDvdGraph.GetFiltergraph(IGraphBuilder(FFilterGraph));
            End;
        End;
        FActive := True;
        // Events
        If Succeeded(QueryInterface(IMediaEventEx, FMediaEventEx)) Then Begin
          FMediaEventEx.SetNotifyFlags(0); // enable events notification
          FMediaEventEx.SetNotifyWindow(FHandle, WM_GRAPHNOTIFY, NativeInt(FMediaEventEx));
        End;

        // Callbacks
        If Succeeded(QueryInterface(IID_IObjectWithSite, Obj)) Then Begin
          QueryInterface(IID_IAMGraphBuilderCallback, Gbcb);
          If Assigned(Gbcb) Then Begin
            Obj.SetSite(Gbcb);
            Gbcb := Nil;
          End;
          QueryInterface(IID_IAMFilterGraphCallback, Fgcb);
          If Assigned(Fgcb) Then Begin
            Obj.SetSite(Fgcb);
            Fgcb := Nil;
          End;
          Obj := Nil;
        End;

        // Remote Object Table
        GraphEdit := FGraphEdit; // Add the Filter Graph to the ROT if needed.
        // Log File
        SetLogFile(FLogFileName);
        // Load Filters
        AddOwnFilters;
        // Notify Controlers
        If Assigned(FOnActivate) Then FOnActivate(Self);
        ControlEvents(CeActive, 1);
      End;
    False: Begin
        ControlEvents(CeActive, 0);
        ClearOwnFilters;
        If FMediaEventEx <> Nil Then Begin
          FMediaEventEx.SetNotifyFlags(AM_MEDIAEVENT_NONOTIFY); // disable events notification
          FMediaEventEx := Nil;
        End;
        If FGraphEditID <> 0 Then Begin
          RemoveGraphFromRot(FGraphEditID);
          FGraphEditID := 0;
        End;
        FFilterGraph.SetLogFile(0);
        If Assigned(FLogFile) Then FreeAndNil(FLogFile);

        FFilterGraph := Nil;
        FCaptureGraph := Nil;
        FDVDGraph := Nil;
        FActive := False;
      End;
  End;
End;

Procedure TFilterGraph.Loaded;
Begin
  If AutoCreate And (Not(CsDesigning In ComponentState)) Then SetActive(True);
  Inherited Loaded;
End;

Procedure TFilterGraph.WndProc(Var Msg: TMessage);
Begin
  With Msg Do
    If Msg = WM_GRAPHNOTIFY Then
      Try
        HandleEvents;
      Except
        Application.HandleException(Self);
      End
    Else Result := DefWindowProc(FHandle, Msg, WParam, LParam);
End;

Procedure TFilterGraph.HandleEvents;
Var
  Hr: HRESULT;
  Event: Integer;
{$IF CompilerVersion >= 35.0}
  Param1, Param2: Longint;
{$ELSE}
  Param1, Param2: Integer;
{$IFEND}
Begin
  If Assigned(FMediaEventEx) Then Begin
    // if you got compiler error on FMediaEventEx.GetEvent with XE7 or newer then
    // delete or remove from search path folder "DSPack\src\DirectX9"
    Hr := FMediaEventEx.GetEvent(Event, Param1, Param2, 0);
    While (Hr = S_OK) Do Begin
      DoEvent(Event, Param1, Param2);
      FMediaEventEx.FreeEventParams(Event, Param1, Param2);
      Hr := FMediaEventEx.GetEvent(Event, Param1, Param2, 0);
    End;
  End;
End;

Procedure TFilterGraph.DoEvent(Event: Integer; Param1, Param2: NativeInt);
Type
  TVideoSize = Record
    Width: WORD;
    Height: WORD;
  End;
Var
  Lcid: Cardinal;
  AchLang: Array [0 .. MAX_PATH] Of Char;
  Tc: TDsPackDVDTimecode;
  Frate: Integer;
  Hmsftc: TDVDHMSFTimeCode;
  DVDInfo2: IDVDInfo2;
Begin
  GraphEvents(Event, Param1, Param2);
  If Assigned(FOnDSEvent) Then FOnDSEvent(Self, Event, Param1, Param2);
  Case Event Of
    EC_BUFFERING_DATA: If Assigned(FOnGraphBufferingData) Then FOnGraphBufferingData(Self, (Param1 = 1));
    EC_CLOCK_CHANGED: If Assigned(FOnGraphClockChanged) Then FOnGraphClockChanged(Self);
    EC_COMPLETE: If Assigned(FOnGraphComplete) Then FOnGraphComplete(Self, Param1, IBaseFilter(Param2));
    EC_DEVICE_LOST: If Assigned(FOnGraphDeviceLost) Then FOnGraphDeviceLost(Self, IUnKnown(Param1), (Param2 = 1));
    EC_END_OF_SEGMENT: If Assigned(FOnGraphEndOfSegment) Then FOnGraphEndOfSegment(Self, PReferenceTime(Param1)^, Param2);
    EC_ERROR_STILLPLAYING: If Assigned(FOnGraphErrorStillPlaying) Then FOnGraphErrorStillPlaying(Self, Param1);
    EC_ERRORABORT: If Assigned(FOnGraphErrorAbort) Then FOnGraphErrorAbort(Self, Param1);
    EC_FULLSCREEN_LOST: If Assigned(FOnGraphFullscreenLost) Then FOnGraphFullscreenLost(Self, IBaseFilter(Param2));
    EC_GRAPH_CHANGED: If Assigned(FOnGraphChanged) Then FOnGraphChanged(Self);
    EC_OLE_EVENT: If Assigned(FOnGraphOleEvent) Then FOnGraphOleEvent(Self, UnicodeString(Param1), UnicodeString(Param2));
    EC_OPENING_FILE: If Assigned(FOnGraphOpeningFile) Then FOnGraphOpeningFile(Self, (Param1 = 1));
    EC_PALETTE_CHANGED: If Assigned(FOnGraphPaletteChanged) Then FOnGraphPaletteChanged(Self);
    EC_PAUSED: If Assigned(FOnGraphPaused) Then FOnGraphPaused(Self, Param1);
    EC_QUALITY_CHANGE: If Assigned(FOnGraphQualityChange) Then FOnGraphQualityChange(Self);
    EC_SNDDEV_IN_ERROR: If Assigned(FOnGraphSNDDevInError) Then FOnGraphSNDDevInError(Self, TSndDevErr(Param1), Param2);
    EC_SNDDEV_OUT_ERROR: If Assigned(FOnGraphSNDDevOutError) Then FOnGraphSNDDevOutError(Self, TSndDevErr(Param1), Param2);
    EC_STEP_COMPLETE: If Assigned(FOnGraphStepComplete) Then FOnGraphStepComplete(Self);
    EC_STREAM_CONTROL_STARTED: If Assigned(FOnGraphStreamControlStarted) Then FOnGraphStreamControlStarted(Self, IPin(Param1), Param2);
    EC_STREAM_CONTROL_STOPPED: If Assigned(FOnGraphStreamControlStopped) Then FOnGraphStreamControlStopped(Self, IPin(Param1), Param2);
    EC_STREAM_ERROR_STILLPLAYING: If Assigned(FOnGraphStreamErrorStillPlaying) Then FOnGraphStreamErrorStillPlaying(Self, Param1, Param2);
    EC_STREAM_ERROR_STOPPED: If Assigned(FOnGraphStreamErrorStopped) Then FOnGraphStreamErrorStopped(Self, Param1, Param2);
    EC_USERABORT: If Assigned(FOnGraphUserAbort) Then FOnGraphUserAbort(Self);
    EC_VIDEO_SIZE_CHANGED: If Assigned(FOnGraphVideoSizeChanged) Then FOnGraphVideoSizeChanged(Self, TVideoSize(Integer(Param1)).Width, TVideoSize(Integer(Param1)).Height);
    EC_TIMECODE_AVAILABLE: If Assigned(FOnGraphTimeCodeAvailable) Then FOnGraphTimeCodeAvailable(Self, IBaseFilter(Param1), Param2);
    EC_EXTDEVICE_MODE_CHANGE: If Assigned(FOnGraphEXTDeviceModeChange) Then FOnGraphEXTDeviceModeChange(Self, Param1, Param2);
    EC_CLOCK_UNSET: If Assigned(FOnGraphClockUnset) Then FOnGraphClockUnset(Self);
    EC_VMR_RENDERDEVICE_SET: If Assigned(FOnGraphVMRRenderDevice) Then FOnGraphVMRRenderDevice(Self, TVMRRenderDevice(Param1));

    EC_DVD_ANGLE_CHANGE: If Assigned(FOnDVDAngleChange) Then FOnDVDAngleChange(Self, Param1, Param2);
    EC_DVD_AUDIO_STREAM_CHANGE: Begin
        If Assigned(FOnDVDAudioStreamChange) Then
          If Succeeded(QueryInterFace(IDVDInfo2, DVDInfo2)) Then Begin
            CheckDSError(DvdInfo2.GetAudioLanguage(Param1, Lcid));
            GetLocaleInfo(Lcid, LOCALE_SENGLANGUAGE, AchLang, MAX_PATH);
            FOnDVDAudioStreamChange(Self, Param1, Lcid, String(AchLang));
            DVDInfo2 := Nil;
          End;
      End;
    EC_DVD_BUTTON_CHANGE: If Assigned(FOnDVDButtonChange) Then FOnDVDButtonChange(Self, Param1, Param2);
    EC_DVD_CHAPTER_AUTOSTOP: If Assigned(FOnDVDChapterAutoStop) Then FOnDVDChapterAutoStop(Self);
    EC_DVD_CHAPTER_START: If Assigned(FOnDVDChapterStart) Then FOnDVDChapterStart(Self, Param1);
    EC_DVD_CURRENT_TIME: Begin
        If Assigned(FOnDVDCurrentTime) Then Begin
          Tc := IntToTimeCode(Param1);
          Case Tc.FrameRateCode Of
            1: Frate := 25;
            3: Frate := 30;
          Else Frate := 0;
          End;
          FOnDVDCurrentTime(Self, Tc.Hours1 + Tc.Hours10 * 10, Tc.Minutes1 + Tc.Minutes10 * 10, Tc.Seconds1 + Tc.Seconds10 * 10, Tc.Frames1 + Tc.Frames10 * 10, Frate);
        End;
      End;
    EC_DVD_DOMAIN_CHANGE: Begin
        Case Param1 Of
          1: If Assigned(FOnDVDDomainFirstPlay) Then FOnDVDDomainFirstPlay(Self);
          2: If Assigned(FOnDVDDomainVideoManagerMenu) Then FOnDVDDomainVideoManagerMenu(Self);
          3: If Assigned(FOnDVDDomainVideoTitleSetMenu) Then FOnDVDDomainVideoTitleSetMenu(Self);
          4: If Assigned(FOnDVDDomainTitle) Then FOnDVDDomainTitle(Self);
          5: If Assigned(FOnDVDDomainStop) Then FOnDVDDomainStop(Self);
        End;
      End;
    EC_DVD_ERROR: Begin
        Case Param1 Of
          1: If Assigned(FOnDVDErrorUnexpected) Then FOnDVDErrorUnexpected(Self);
          2: If Assigned(FOnDVDErrorCopyProtectFail) Then FOnDVDErrorCopyProtectFail(Self);
          3: If Assigned(FOnDVDErrorInvalidDVD1_0Disc) Then FOnDVDErrorInvalidDVD1_0Disc(Self);
          4: If Assigned(FOnDVDErrorInvalidDiscRegion) Then FOnDVDErrorInvalidDiscRegion(Self);
          5: If Assigned(FOnDVDErrorLowParentalLevel) Then FOnDVDErrorLowParentalLevel(Self);
          6: If Assigned(FOnDVDErrorMacrovisionFail) Then FOnDVDErrorMacrovisionFail(Self);
          7: If Assigned(FOnDVDErrorIncompatibleSystemAndDecoderRegions) Then FOnDVDErrorIncompatibleSystemAndDecoderRegions(Self);
          8: If Assigned(FOnDVDErrorIncompatibleDiscAndDecoderRegions) Then FOnDVDErrorIncompatibleDiscAndDecoderRegions(Self);
        End;
      End;
    EC_DVD_NO_FP_PGC: If Assigned(FOnDVDNoFP_PGC) Then FOnDVDNoFP_PGC(Self);
    EC_DVD_STILL_OFF: If Assigned(FOnDVDStillOff) Then FOnDVDStillOff(Self);
    EC_DVD_STILL_ON: If Assigned(FOnDVDStillOn) Then FOnDVDStillOn(Self, (Param1 = 1), Param2);
    EC_DVD_SUBPICTURE_STREAM_CHANGE: Begin
        If Assigned(FOnDVDSubpictureStreamChange) And Succeeded(QueryInterFace(IDVDInfo2, DVDInfo2)) Then Begin
          DvdInfo2.GetSubpictureLanguage(Param1, Lcid);
          GetLocaleInfo(Lcid, LOCALE_SENGLANGUAGE, AchLang, MAX_PATH);
          FOnDVDSubpictureStreamChange(Self, Param1, Lcid, String(AchLang));
          DVDInfo2 := Nil;
        End;
      End;
    EC_DVD_TITLE_CHANGE: If Assigned(FOnDVDTitleChange) Then FOnDVDTitleChange(Self, Param1);
    EC_DVD_VALID_UOPS_CHANGE: If Assigned(FOnDVDValidUOPSChange) Then FOnDVDValidUOPSChange(Self, Param1);
    EC_DVD_WARNING: Begin
        Case Param1 Of
          1: If Assigned(FOnDVDWarningInvalidDVD1_0Disc) Then FOnDVDWarningInvalidDVD1_0Disc(Self);
          2: If Assigned(FOnDVDWarningFormatNotSupported) Then FOnDVDWarningFormatNotSupported(Self);
          3: If Assigned(FOnDVDWarningIllegalNavCommand) Then FOnDVDWarningIllegalNavCommand(Self);
          4: If Assigned(FOnDVDWarningOpen) Then FOnDVDWarningOpen(Self);
          5: If Assigned(FOnDVDWarningSeek) Then FOnDVDWarningSeek(Self);
          6: If Assigned(FOnDVDWarningRead) Then FOnDVDWarningRead(Self);
        End;
      End;
    EC_DVD_PLAYBACK_RATE_CHANGE: If Assigned(FOnDVDPlaybackRateChange) Then FOnDVDPlaybackRateChange(Self, Param1 / 10000);
    EC_DVD_PARENTAL_LEVEL_CHANGE: If Assigned(FOnDVDParentalLevelChange) Then FOnDVDParentalLevelChange(Self, Param1);
    EC_DVD_PLAYBACK_STOPPED: If Assigned(FOnDVDPlaybackStopped) Then FOnDVDPlaybackStopped(Self);
    EC_DVD_ANGLES_AVAILABLE: If Assigned(FOnDVDAnglesAvailable) Then FOnDVDAnglesAvailable(Self, (Param1 = 1));
    EC_DVD_PLAYPERIOD_AUTOSTOP: If Assigned(FOnDVDPlayPeriodAutoStop) Then FOnDVDPlayPeriodAutoStop(Self);
    EC_DVD_BUTTON_AUTO_ACTIVATED: If Assigned(FOnDVDButtonAutoActivated) Then FOnDVDButtonAutoActivated(Self, Param1);
    EC_DVD_CMD_START: If Assigned(FOnDVDCMDStart) Then FOnDVDCMDStart(Self, Param1);
    EC_DVD_CMD_END: If Assigned(FOnDVDCMDEnd) Then FOnDVDCMDEnd(Self, Param1);
    EC_DVD_DISC_EJECTED: If Assigned(FOnDVDDiscEjected) Then FOnDVDDiscEjected(Self);
    EC_DVD_DISC_INSERTED: If Assigned(FOnDVDDiscInserted) Then FOnDVDDiscInserted(Self);
    EC_DVD_CURRENT_HMSF_TIME: Begin
        If Assigned(FOnDVDCurrentHMSFTime) Then Begin
          Hmsftc := TDVDHMSFTimeCode(Integer(Param1));
          Tc := IntToTimeCode(Param2);
          FOnDVDCurrentHMSFTime(Self, Hmsftc, Tc);
        End;
      End;
    EC_DVD_KARAOKE_MODE: If Assigned(FOnDVDKaraokeMode) Then FOnDVDKaraokeMode(Self, BOOL(Param1));
  End;
End;

Function TFilterGraph.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  Result := Inherited QueryInterface(IID, Obj);
  If (Not Succeeded(Result)) And Active Then
    Case FMode Of
      GmNormal: Result := FFilterGraph.QueryInterface(IID, Obj);
      GmCapture: Begin
          Result := FCaptureGraph.QueryInterface(IID, Obj);
          If Not Succeeded(Result) Then Result := FFilterGraph.QueryInterface(IID, Obj);
        End;
      GmDVD: Begin
          Result := FDvdGraph.QueryInterface(IID, Obj);
          If Not Succeeded(Result) Then Result := FDvdGraph.GetDvdInterface(IID, Obj);
          If Not Succeeded(Result) Then Result := FFilterGraph.QueryInterface(IID, Obj);
        End;
    End;
End;

Procedure TFilterGraph.SetGraphEdit(Enable: Boolean);
Begin
  Case Enable Of
    True: Begin
        If FGraphEditID = 0 Then
          If Active Then AddGraphToRot(IFilterGraph2(FFilterGraph), FGraphEditID);
      End;
    False: Begin
        If FGraphEditID <> 0 Then Begin
          RemoveGraphFromRot(FGraphEditID);
          FGraphEditID := 0;
        End;
      End;
  End;
  FGraphEdit := Enable;
End;

Procedure TFilterGraph.InsertFilter(AFilter: IFilter);
Var
  FilterName: UnicodeString;
Begin
  If FFilters = Nil Then FFilters := TInterfaceList.Create;
  FFilters.Add(AFilter);
  If Active Then Begin
    AFilter.NotifyFilter(FoAdding);
    FilterName := AFilter.GetName;
    FFilterGraph.AddFilter(AFilter.GetFilter, PWideChar(FilterName));
    AFilter.NotifyFilter(FoAdded);
  End;
End;

Procedure TFilterGraph.RemoveFilter(AFilter: IFilter);
Begin
  FFilters.Remove(AFilter);
  If Active Then Begin
    AFilter.NotifyFilter(FoRemoving);
    FFilterGraph.RemoveFilter(AFilter.GetFilter);
    AFilter.NotifyFilter(FoRemoved);
  End;
  If FFilters.Count = 0 Then FreeAndNil(FFilters);
End;

Procedure TFilterGraph.InsertEventNotifier(AEvent: IEvent);
Begin
  If FGraphEvents = Nil Then FGraphEvents := TInterFaceList.Create;
  FGraphEvents.Add(AEvent);
End;

Procedure TFilterGraph.RemoveEventNotifier(AEvent: IEvent);
Begin
  If FGraphEvents <> Nil Then Begin
    FGraphEvents.Remove(AEvent);
    If FGraphEvents.Count = 0 Then FreeAndNil(FGraphEvents);
  End;
End;

Procedure TFilterGraph.ClearOwnFilters;
Var
  I: Integer;
Begin
  If Active And (FFilters <> Nil) Then
    For I := 0 To FFilters.Count - 1 Do Begin
      IFilter(FFilters.Items[I]).NotifyFilter(FoRemoving);
      FFilterGraph.RemoveFilter(IFilter(FFilters.Items[I]).GetFilter);
      IFilter(FFilters.Items[I]).NotifyFilter(FoRemoved);
    End;
End;

Procedure TFilterGraph.AddOwnFilters;
Var
  I: Integer;
  FilterName: UnicodeString;
Begin
  If Active And (FFilters <> Nil) Then
    For I := 0 To FFilters.Count - 1 Do Begin
      IFilter(FFilters.Items[I]).NotifyFilter(FoAdding);
      FilterName := IFilter(FFilters.Items[I]).GetName;
      FFilterGraph.AddFilter(IFilter(FFilters.Items[I]).GetFilter, PWideChar(FilterName));
      IFilter(FFilters.Items[I]).NotifyFilter(FoAdded);
    End;
End;

{
  procedure TFilterGraph.NotifyFilters(operation: TFilterOperation; Param: integer);
  var i: integer;
  begin
  if FFilters <> nil then
  for i := 0 to FFilters.Count - 1 do
  IFilter(FFilters.Items[i]).NotifyFilter(operation, Param);

  end;
}

Procedure TFilterGraph.GraphEvents(Event, Param1, Param2: Integer);
Var
  I: Integer;
Begin
  If FGraphEvents <> Nil Then
    For I := 0 To FGraphEvents.Count - 1 Do IEvent(FGraphEvents.Items[I]).GraphEvent(Event, Param1, Param2);
End;

Procedure TFilterGraph.ControlEvents(Event: TControlEvent; Param: Integer = 0);
Var
  I: Integer;
Begin
  If FGraphEvents <> Nil Then
    For I := 0 To FGraphEvents.Count - 1 Do IEvent(FGraphEvents.Items[I]).ControlEvent(Event, Param);
End;

Function TFilterGraph.Play: Boolean;
Var
  MediaControl: IMediaControl;
Begin
  Result := False;
  If Succeeded(QueryInterface(IMediaControl, MediaControl)) Then Begin
    ControlEvents(CePlay);
    Result := Succeeded((CheckDSError(MediaControl.Run)));
    MediaControl := Nil;
  End;
End;

Function TFilterGraph.Pause: Boolean;
Var
  MediaControl: IMediaControl;
Begin
  Result := False;
  If Succeeded(QueryInterface(IMediaControl, MediaControl)) Then Begin
    ControlEvents(CePause);
    Result := (CheckDSError(MediaControl.Pause) = S_OK);
    MediaControl := Nil;
  End;
End;

Function TFilterGraph.Stop: Boolean;
Var
  MediaControl: IMediaControl;
Begin
  Result := False;
  If Succeeded(QueryInterface(IMediaControl, MediaControl)) Then Begin
    ControlEvents(CeStop);
    Result := (CheckDSError(MediaControl.Stop) = S_OK);
    MediaControl := Nil;
  End;
End;

Procedure TFilterGraph.SetLogFile(FileName: String);
Begin
  If Active Then Begin
    FFilterGraph.SetLogFile(0);
    If Assigned(FLogFile) Then FreeAndNil(FLogFile);
    If FileName <> '' Then
      Try

        FLogFile := TFileStream.Create(FileName, FmCreate{$IFDEF VER140}, FmShareDenyNone{$ENDIF});

        FFilterGraph.SetLogFile(FLogFile.Handle);
      Except
        FFilterGraph.SetLogFile(0);
        If Assigned(FLogFile) Then FreeAndNil(FLogFile);
        Exit;
      End;
  End;
  FLogFileName := FileName;
End;

Procedure TFilterGraph.DisconnectFilters;
Var
  FilterList: TFilterList;
  PinList: TPinList;
  BaseFilter: IBaseFilter;
  I, J: Integer;
Begin
  If Assigned(FFilterGraph) Then Begin
    FilterList := TFilterList.Create(FFilterGraph);
    If FilterList.Count > 0 Then
      For I := 0 To FilterList.Count - 1 Do Begin
        BaseFilter := FilterList.Items[I] As IBaseFilter;
        PinList := TPinList.Create(BaseFilter);
        If PinList.Count > 0 Then
          For J := 0 To PinList.Count - 1 Do CheckDSError(IPin(PinList.Items[J]).Disconnect);
        PinList.Free;
        BaseFilter := Nil;
      End;
    FilterList.Free;
  End;
End;

Procedure TFilterGraph.ClearGraph;
Var
  I: Integer;
  FilterList: TFilterList;
Begin
  If Assigned(FFilterGraph) Then Begin
    Stop;
    DisconnectFilters;
    FilterList := TFilterList.Create(FFilterGraph);
    If Assigned(FFilters) Then
      If FFilters.Count > 0 Then
        For I := 0 To FFilters.Count - 1 Do FilterList.Remove(IFilter(FFilters.Items[I]).GetFilter);
    If FilterList.Count > 0 Then
      For I := 0 To FilterList.Count - 1 Do CheckDSError(FFilterGraph.RemoveFilter(FilterList.Items[I]));
    FilterList.Free;
  End;
End;

Function TFilterGraph.GetState: TGraphState;
Var
  AState: TFilterState;
  MediaControl: IMediaControl;
Begin
  Result := GsUninitialized;
  If Succeeded(QueryInterface(IMediaControl, MediaControl)) Then Begin
    MediaControl.GetState(0, AState);
    Case AState Of
      State_Stopped: Result := GsStopped;
      State_Paused: Result := GsPaused;
      State_Running: Result := GsPlaying;
    End;
    MediaControl := Nil;
  End;
End;

Procedure TFilterGraph.SetState(Value: TGraphState);
Var
  MediaControl: IMediaControl;
  Hr: HResult;
Begin
  If Succeeded(QueryInterface(IMediaControl, MediaControl)) Then Begin
    Case Value Of
      GsStopped: Hr := MediaControl.Stop;
      GsPaused: Hr := MediaControl.Pause;
      GsPlaying: Hr := MediaControl.Run;
    Else Hr := S_OK;
    End;
    MediaControl := Nil;
    CheckDSError(Hr);
  End;
End;

Procedure TFilterGraph.SetVolume(Volume: Integer);
Var
  BasicAudio: IBasicAudio;
Begin
  FVolume := EnsureRange(Volume, 0, 10000);
  If Succeeded(QueryInterface(IBasicAudio, BasicAudio)) Then Begin
    If FLinearVolume Then BasicAudio.Put_Volume(SetBasicAudioVolume(FVolume))
    Else BasicAudio.Put_Volume(FVolume - 10000);
    BasicAudio := Nil;
  End;
End;

Procedure TFilterGraph.SetBalance(Balance: Integer);
Var
  BasicAudio: IBasicAudio;
Begin
  FBalance := EnsureRange(Balance, -10000, 10000);
  If Succeeded(QueryInterface(IBasicAudio, BasicAudio)) Then Begin
    If FLinearVolume Then BasicAudio.Put_Balance(SetBasicAudioPan(FBalance))
    Else BasicAudio.Put_Balance(FBalance);
    BasicAudio := Nil;
  End;
End;

Function TFilterGraph.GetSeekCaps: TSeekingCaps;
Var
  MediaSeeking: IMediaSeeking;
  Flags: Cardinal;
Begin
  Result := [];
  If Succeeded(QueryInterface(IMediaSeeking, MediaSeeking)) Then Begin
    MediaSeeking.GetCapabilities(Flags);
    PByte(@Result)^ := Flags;
    MediaSeeking := Nil;
  End;
End;

Function TFilterGraph.RenderFile(FileName: UnicodeString): HRESULT;
Begin
  Result := S_FALSE;
  If Assigned(FFilterGraph) Then Begin
    ControlEvents(CeFileRendering);
    Result := CheckDSError(FFilterGraph.RenderFile(PWideChar(FileName), Nil));
    If Succeeded(Result) Then Begin
      UpdateGraph;
      ControlEvents(CeFileRendered);
    End;
  End;
End;

{ TODO -oHG : Add the audio rendering }
Function TFilterGraph.RenderFileEx(FileName: UnicodeString): HRESULT;
Var
  SourceFilter: IBaseFilter;
  PinList: TPinList;
  I: Integer;
Begin
  Result := S_FALSE;
  If Assigned(FFilterGraph) Then Begin
    ControlEvents(CeFileRendering);
    CheckDSError(FFilterGraph.AddSourceFilter(PWideChar(FileName), PWideChar(FileName), SourceFilter));
    PinList := TPinList.Create(SourceFilter);
    Try
      For I := 0 To PinList.Count - 1 Do Begin
        CheckDSError(IFilterGraph2(FFilterGraph).RenderEx(PinList.Items[I], AM_RENDEREX_RENDERTOEXISTINGRENDERERS, Nil));
      End;
    Finally
      PinList.Free;
    End;
    If Succeeded(Result) Then Begin
      ControlEvents(CeFileRendered);
      UpdateGraph;
    End;
  End;
End;

Function TFilterGraph.RenderDVD(Out Status: TAMDVDRenderStatus; FileName: UnicodeString = ''; Mode: Integer = AM_DVD_HWDEC_PREFER): HRESULT;
Begin
  Result := HRESULT(VFW_E_DVD_RENDERFAIL);
  If Assigned(FDVDGraph) Then Begin
    ControlEvents(CeDVDRendering, Mode);
    If FileName <> '' Then Result := CheckDSError(FDVDGraph.RenderDvdVideoVolume(PWideChar(FileName), Mode, Status))
    Else Result := CheckDSError(FDVDGraph.RenderDvdVideoVolume(Nil, Mode, Status));
    If Result In [S_OK .. S_FALSE] Then Begin
      ControlEvents(CeDVDRendered, Mode);
      UpdateGraph;
    End;
  End;
End;

Procedure TFilterGraph.SetRate(Rate: Double);
Var
  MediaSeeking: IMediaSeeking;
Begin
  FRate := Rate;
  If Succeeded(QueryInterface(IMediaSeeking, MediaSeeking)) Then Begin
    MediaSeeking.SetRate(FRate);
    MediaSeeking := Nil;
  End;
End;

Function TFilterGraph.GetDuration: Integer;
Var
  MediaSeeking: IMediaSeeking;
  RefTime: Int64;
Begin
  If Succeeded(QueryInterface(IMediaSeeking, MediaSeeking)) Then Begin
    MediaSeeking.GetDuration(RefTime);
    Result := RefTimeToMiliSec(RefTime);
    MediaSeeking := Nil;
  End
  Else Result := 0;
End;

Function TFilterGraph.GetPosition: Integer;
Var
  MediaSeeking: IMediaSeeking;
  RefTime: Int64;
Begin
  If Succeeded(QueryInterface(IMediaSeeking, MediaSeeking)) Then Begin
    MediaSeeking.GetCurrentPosition(RefTime);
    Result := RefTimeToMiliSec(RefTime);
    MediaSeeking := Nil;
  End
  Else Result := 0;
End;

Procedure TFilterGraph.SetPosition(APosition: Integer);
Var
  MediaSeeking: IMediaSeeking;
  RefTime: Int64;
Begin
  If Succeeded(QueryInterface(IMediaSeeking, MediaSeeking)) Then Begin
    RefTime := MiliSecToRefTime(APosition);
    MediaSeeking.SetPositions(RefTime, AM_SEEKING_AbsolutePositioning, RefTime, AM_SEEKING_NoPositioning);
    MediaSeeking := Nil;
  End
End;

Procedure TFilterGraph.DVDSaveBookmark(BookMarkFile: UnicodeString);
Var
  DVDInfo2: IDVDInfo2;
  Bookmark: IDvdState;
  PStorage: IStorage;
  PStream: IStream;
  PersistStream: IPersistStream;
Begin
  If Active And (Mode = GmDVD) Then
    If Succeeded(QueryInterface(IDVDInfo2, DVDInfo2)) Then Begin
      DVDInfo2.GetState(Bookmark);
      StgCreateDocfile(PWideChar(BookMarkFile), STGM_CREATE Or STGM_WRITE Or STGM_SHARE_EXCLUSIVE, 0, PStorage);
      PStorage.CreateStream('BookMark', STGM_CREATE Or STGM_WRITE Or STGM_SHARE_EXCLUSIVE, 0, 0, PStream);
      If Succeeded(Bookmark.QueryInterface(IID_IPersistStream, PersistStream)) Then Begin
        OleSaveToStream(PersistStream, PStream);
        PersistStream := Nil;
      End Else Begin
        PersistStream := Nil;
        DVDInfo2 := Nil;
        Exit;
      End;
      DVDInfo2 := Nil;
    End;
End;

Procedure TFilterGraph.DVDRestoreBookmark(BookMarkFile: UnicodeString);
Var
  DVDControl2: IDvdControl2;
  PStorage: IStorage;
  PStream: IStream;
  PBookmark: IDvdState;
  Hr: HRESULT;
  Obj: IDVDCmd;
Begin
  If Succeeded(QueryInterface(IDvdControl2, DvdControl2)) Then Begin
    StgOpenStorage(PWideChar(BookMarkFile), Nil, STGM_READ Or STGM_SHARE_EXCLUSIVE, Nil, 0, PStorage);
    PStorage.OpenStream('BookMark', Nil, STGM_READ Or STGM_SHARE_EXCLUSIVE, 0, PStream);
    OleLoadFromStream(PStream, IID_IDvdState, PBookmark);
    Hr := CheckDSError(DVDControl2.SetState(PBookmark, DVD_CMD_FLAG_None, Obj));
    If Not(Failed(Hr)) Then Begin
      Obj.WaitForEnd;
      Obj := Nil;
    End;
    DvdControl2 := Nil;
  End;
End;

Procedure TFilterGraph.SetLinearVolume(AEnabled: Boolean);
Begin
  If FLinearVolume = AEnabled Then Exit;
  FLinearVolume := AEnabled;
  SetVolume(FVolume);
  SetBalance(FBalance);
End;

Procedure TFilterGraph.UpdateGraph;
Begin
  SetVolume(FVolume);
  SetBalance(FBalance);
  SetRate(FRate);
End;

Function TFilterGraph.SelectedFilter(PMon: IMoniker): HResult; Stdcall;
Var
  PropBag: IPropertyBag;
  Name: OleVariant;
  VGuid: OleVariant;
  Guid: TGUID;
Begin
  If Assigned(FOnSelectedFilter) Then Begin
    PMon.BindToStorage(Nil, Nil, IID_IPropertyBag, PropBag);
    If PropBag.Read('CLSID', VGuid, Nil) = S_OK Then Guid := StringToGUID(VGuid)
    Else Guid := GUID_NULL;
    If PropBag.Read('FriendlyName', Name, Nil) <> S_OK Then Name := '';

    PropBag := Nil;

    If FOnSelectedFilter(PMon, Name, Guid) Then Result := S_OK
    Else Result := E_FAIL;
  End
  Else Result := S_OK;
End;

Function TFilterGraph.CreatedFilter(PFil: IBaseFilter): HResult; Stdcall;
Var
  Guid: TGuid;
Begin
  If Assigned(FOnCreatedFilter) Then Begin
    Pfil.GetClassID(Guid);
    If FOnCreatedFilter(PFil, Guid) Then Result := S_OK
    Else Result := E_FAIL;
  End
  Else Result := S_OK;
End;

Function TFilterGraph.UnableToRender(Ph1, Ph2: Integer; PPin: IPin): HResult;
Var
  Graph: TFilterGraph;
  PinInfo: TPinInfo;
  FilterInfo: TFilterInfo;
  ServiceProvider: IServiceProvider;
Begin
  Result := S_FALSE;

  If (PPin.QueryPinInfo(PinInfo) = S_OK) And (Assigned(PinInfo.PFilter)) And (PinInfo.PFilter.QueryFilterInfo(FilterInfo) = S_OK) And (Assigned(FilterInfo.PGraph)) And (FilterInfo.PGraph.QueryInterface(IServiceProvider, ServiceProvider) = S_OK) And (ServiceProvider.QueryService(CLSID_FilterGraphCallback, CLSID_FilterGraphCallback, Graph) = S_OK) And (Assigned(Graph) And Assigned(Graph.FOnUnableToRender)) And (Graph.FOnUnableToRender(PPin)) Then Result := S_OK;

  PinInfo.PFilter := Nil;
  FilterInfo.PGraph := Nil;
  ServiceProvider := Nil;
End;

Function TFilterGraph.QueryService(Const Rsid, Iid: TGuid; Out Obj): HResult;
Begin
  If IsEqualGUID(CLSID_FilterGraphCallback, Rsid) And IsEqualGUID(CLSID_FilterGraphCallback, Iid) Then Begin
    Pointer(Obj) := Pointer(Self);
    Result := S_OK;
  End
  Else Result := E_NOINTERFACE;
End;

// ******************************************************************************
// TVMROptions
// ******************************************************************************

Constructor TVMROptions.Create(AOwner: TVideoWindow);
Begin
  FPreferences := [VpForceMixer];
  FStreams := 4;
  FOwner := AOwner;
  FMode := VmrWindowed;
  FKeepAspectRatio := True;
End;

Procedure TVMROptions.SetStreams(Streams: Cardinal);
Begin
  If Streams In [1 .. 16] Then FStreams := Streams
  Else FStreams := 1;
  With FOwner Do Begin
    If (Mode <> VmVMR) Or (FilterGraph = Nil) Then Exit;
    If Not FilterGraph.Active Then Exit;
    // need to reconnect
    FilterGraph.RemoveFilter(FOwner);
    FilterGraph.InsertFilter(FOwner);
  End;
End;

Procedure TVMROptions.SetPreferences(Preferences: TVMRPreferences);
Begin
  FPreferences := Preferences;
  With FOwner Do Begin
    If (Mode <> VmVMR) Or (FilterGraph = Nil) Then Exit;
    If Not FilterGraph.Active Then Exit;
    // need to reconnect
    FilterGraph.RemoveFilter(FOwner);
    FilterGraph.InsertFilter(FOwner);
  End;
End;

Procedure TVMROptions.SetMode(AMode: TVMRVideoMode);
Begin
  FMode := AMode;
  With FOwner Do Begin
    If (Mode <> VmVMR) Or (FilterGraph = Nil) Then Exit;
    If Not FilterGraph.Active Then Exit;
    // need to reconnect
    FilterGraph.RemoveFilter(FOwner);
    FilterGraph.InsertFilter(FOwner);
  End;
End;

Procedure TVMROptions.SetKeepAspectRatio(Keep: Boolean);
Var
  AspectRatioControl: IVMRAspectRatioControl9;
Begin
  FKeepAspectRatio := Keep;
  Case Mode Of
    VmrWindowed, VmrWindowless: Begin
        If Succeeded(FOwner.QueryInterface(IVMRAspectRatioControl9, AspectRatioControl)) Then
          Case Keep Of
            True: CheckDSError(AspectRatioControl.SetAspectRatioMode(VMR_ARMODE_LETTER_BOX));
            False: CheckDSError(AspectRatioControl.SetAspectRatioMode(VMR_ARMODE_NONE));
          End;

      End;
    VmrRenderless: { TODO };
  End;
End;


// ******************************************************************************
// TVideoWindow
// ******************************************************************************

Constructor TVideoWindow.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FVMROptions := TVMROptions.Create(Self);
  ControlStyle := [CsAcceptsControls, CsCaptureMouse, CsClickEvents, CsDoubleClicks, CsReflector];
  TabStop := True;
  Height := 120;
  Width := 160;
  Color := $000000;
  FIsFullScreen := False;
  FKeepAspectRatio := True;
End;

Destructor TVideoWindow.Destroy;
Begin
  FVMROptions.Free;
  FilterGraph := Nil;
  Inherited Destroy;
End;

Procedure TVideoWindow.SetVideoMode(AMode: TVideoMode);
Begin
  If (AMode = VmVMR) And (Not CheckVMR) Then FMode := VmNormal
  Else FMode := AMode;
  If FilterGraph = Nil Then Exit;
  If Not FilterGraph.Active Then Exit;
  // need to reconnect
  FilterGraph.RemoveFilter(Self);
  FilterGraph.InsertFilter(Self);
End;

Procedure TVideoWindow.Loaded;
Begin
  Inherited Loaded;
  FWindowStyle := GetWindowLong(Handle, GWL_STYLE);
  FWindowStyleEx := GetWindowLong(Handle, GWL_EXSTYLE);
End;

Procedure TVideoWindow.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then FFilterGraph := Nil;
End;

Procedure TVideoWindow.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then Begin
    FFilterGraph.RemoveFilter(Self);
    FFilterGraph.RemoveEventNotifier(Self);
  End;
  If AFilterGraph <> Nil Then Begin
    AFilterGraph.InsertFilter(Self);
    AFilterGraph.InsertEventNotifier(Self);
  End;
  FFilterGraph := AFilterGraph;
End;

Function TVideoWindow.GetFilter: IBaseFilter;
Begin
  Result := FBaseFilter;
End;

Function TVideoWindow.GetName: String;
Begin
  Result := Name;
End;

Procedure TVideoWindow.NotifyFilter(Operation: TFilterOperation; Param: Integer);
Var
  EnumPins: TPinList;
  VMRFilterConfig: IVMRFilterConfig9;
  VMRSurfaceAllocatorNotify: IVMRSurfaceAllocatorNotify9;
  VMRSurfaceAllocator: IVMRSurfaceAllocator9;
  MyPrefs: TVMRPreferences;
  APrefs: Cardinal;
  I: Integer;
  CW: Word;
  Hr: HResult;
  DSPackException: EDSPackException;

  Procedure UpdatePreferences;
  Begin
    // VMR9 preferences
    MyPrefs := FVMROptions.FPreferences - [VpForceMixer];
    CheckDSError(VMRFilterConfig.SetRenderingPrefs(PByte(@MyPrefs)^));
    APrefs := 0;
    CheckDSError(VMRFilterConfig.GetRenderingPrefs(APrefs));
    If (VpForceMixer In FVMROptions.FPreferences) Then FVMROptions.FPreferences := PVMRPreferences(@APrefs)^ + [VpForceMixer]
    Else FVMROptions.FPreferences := PVMRPreferences(@APrefs)^;
  End;

Begin
  Case Operation Of
    FoAdding: Begin
        Case Mode Of
          VmVMR: Begin
              CW := Get8087CW;
              Try
                CoCreateInstance(CLSID_VideoMixingRenderer9, Nil, CLSCTX_INPROC, IID_IBaseFilter, FBaseFilter);
                FBaseFilter.QueryInterface(IVMRFilterConfig9, VMRFilterConfig);
                Case FVMROptions.Mode Of
                  VmrWindowed: CheckDSError(VMRFilterConfig.SetRenderingMode(VMR9Mode_Windowed));
                  VmrWindowless: CheckDSError(VMRFilterConfig.SetRenderingMode(VMR9Mode_Windowless));
                  VmrRenderless: Begin
                      If (FAllocatorClass = Nil) Then Raise EDSPackException.Create('Allocator class not set.');

                      FCurrentAllocator := FAllocatorClass.Create(Hr, Handle);
                      If Failed(Hr) Then Begin
                        DSPackException := EDSPackException.Create('Error Creating Allocator');
                        DSPackException.ErrorCode := Hr;
                        Raise DSPackException;
                      End;

                      CheckDSError(VMRFilterConfig.SetRenderingMode(VMR9Mode_Renderless));
                      CheckDSError(FBaseFilter.QueryInterface(IID_IVMRSurfaceAllocatorNotify9, VMRSurfaceAllocatorNotify));
                      CheckDSError(FCurrentAllocator.QueryInterface(IID_IVMRSurfaceAllocator9, VMRSurfaceAllocator));

                      VMRSurfaceAllocatorNotify.AdviseSurfaceAllocator(FRenderLessUserID, VMRSurfaceAllocator);
                      VMRSurfaceAllocator._AddRef; // manual increment;
                      VMRSurfaceAllocator.AdviseNotify(VMRSurfaceAllocatorNotify);
                    End;
                End;
                VMRFilterConfig := Nil;
              Finally
                Set8087CW(CW);
              End;
            End;
          VmNormal: CoCreateInstance(CLSID_VideoRenderer, Nil, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
        End;
      End;
    FoAdded: Begin
        Case Mode Of
          VmVMR: Begin
              If (FBaseFilter <> Nil) Then
                If CheckDSError(FBaseFilter.QueryInterface(IVMRFilterConfig9, VMRFilterConfig)) = S_OK Then Begin
                  If (FVMROptions.FStreams <> 4) Or (VpForceMixer In FVMROptions.FPreferences) Then Begin
                    CheckDSError(VMRFilterConfig.SetNumberOfStreams(FVMROptions.FStreams));
                    CheckDSError(VMRFilterConfig.GetNumberOfStreams(FVMROptions.FStreams));
                  End;

                  Case FVMROptions.Mode Of
                    VmrWindowed: Begin

                        CheckDSError(FBaseFilter.QueryInterface(IVideoWindow, FVideoWindow));
                        UpdatePreferences;
                      End;
                    VmrWindowless: Begin

                        CheckDSError(FBaseFilter.QueryInterface(IVMRWindowlessControl9, FWindowLess));
                        CheckDSError(FWindowLess.SetVideoClippingWindow(Handle));
                        UpdatePreferences;
                        Resize;
                      End;
                    VmrRenderless: Begin
                        // Assert(False, 'not yet imlemented.');
                        // CheckDSError(FBaseFilter.QueryInterface(IVMRWindowlessControl9, FWindowLess));
                        // CheckDSError(FWindowLess.SetVideoClippingWindow(Handle));
                      End;

                  End;
                  VMRFilterConfig := Nil;
                  VMROptions.SetKeepAspectRatio(VMROptions.FKeepAspectRatio);
                End;
            End;
          VmNormal: CheckDSError(FBaseFilter.QueryInterface(IVideoWindow, FVideoWindow));
        End;
      End;
    FoRemoving: If FBaseFilter <> Nil Then Begin
        // it's important to stop and disconnect the filter before removing the VMR filter.
        CheckDSError(FBaseFilter.Stop);
        EnumPins := TPinList.Create(FBaseFilter);
        If EnumPins.Count > 0 Then
          For I := 0 To EnumPins.Count - 1 Do CheckDSError(EnumPins.Items[I].Disconnect);
        EnumPins.Free;
        If (FCurrentAllocator <> Nil) And (Mode = VmVMR) And (VMROptions.Mode = VmrRenderless) Then Begin
          IUnKnown(FCurrentAllocator)._Release;
          FCurrentAllocator := Nil;
        End;
      End;
    FoRemoved: Begin
        FVideoWindow := Nil;
        FWindowLess := Nil;
        FBaseFilter := Nil;
      End;
  End;
End;

Procedure TVideoWindow.Paint;
Begin
  Inherited Paint;
  If Assigned(FOnPaint) Then FOnPaint(Self);
End;

Procedure TVideoWindow.Resize;
Var
  ARect: TRect;
Begin
  Inherited Resize;
  Case FMode Of
    VmNormal: Begin
        If (FVideoWindow <> Nil) And (Not FullScreen) Then
          If FIsVideoWindowOwner Then FVideoWindow.SetWindowPosition(0, 0, Width, Height)
          Else FVideoWindow.SetWindowPosition(Left, Top, Width, Height);
      End;
    VmVMR: Case FVMROptions.Mode Of
        VmrWindowed: Begin
            If (FVideoWindow <> Nil) And (Not FullScreen) Then
              If FIsVideoWindowOwner Then FVideoWindow.SetWindowPosition(0, 0, Width, Height)
              Else FVideoWindow.SetWindowPosition(Left, Top, Width, Height);
          End;
        VmrWindowless: If FWindowLess <> Nil Then Begin
            ARect := Rect(0, 0, Width, Height);
            FWindowLess.SetVideoPosition(Nil, @ARect);
          End;
      End;
  End;

End;

Procedure TVideoWindow.ConstrainedResize(Var MinWidth, MinHeight, MaxWidth, MaxHeight: Integer);
Begin
  Inherited ConstrainedResize(MinWidth, MinHeight, MaxWidth, MaxHeight);
  Resize;
End;

Function TVideoWindow.GetVideoHandle: THandle;
Begin
  If FVideoWindow <> Nil Then Result := FindWindowEx(Parent.Handle, 0, Pchar('VideoRenderer'), Pchar(Name))
  Else Result := Canvas.Handle;
End;

Class Function TVideoWindow.CheckVMR: Boolean;
Var
  AFilter: IBaseFilter;
  CW: Word;
Begin
  CW := Get8087CW;
  Try
    Result := (CoCreateInstance(CLSID_VideoMixingRenderer9, Nil, CLSCTX_INPROC, IID_IBaseFilter, AFilter) = S_OK);
  Finally
    Set8087CW(CW);
    AFilter := Nil;
  End;
End;

Procedure TVideoWindow.SetFullScreen(Value: Boolean);
Var
  StyleEX: LongWord;
Begin
  If (FVideoWindow <> Nil) And CheckInputPinsConnected Then
    Case Value Of
      True: Begin
          CheckDSError(FVideoWindow.Put_Owner(0));
          CheckDSError(FVideoWindow.Put_WindowStyle(FWindowStyle And Not(WS_BORDER Or WS_CAPTION Or WS_THICKFRAME)));
          StyleEX := FWindowStyleEx And Not(WS_EX_CLIENTEDGE Or WS_EX_STATICEDGE Or WS_EX_WINDOWEDGE Or WS_EX_DLGMODALFRAME);
          If FTopMost Then StyleEX := StyleEX Or WS_EX_TOPMOST;
          CheckDSError(FVideoWindow.Put_WindowStyleEx(StyleEX));
          CheckDSError(FVideoWindow.SetWindowPosition(0, 0, Screen.Width, Screen.Height));
          FIsFullScreen := True;
        End;
      False: Begin
          If FIsVideoWindowOwner Then CheckDSError(FVideoWindow.Put_Owner(Handle))
          Else CheckDSError(FVideoWindow.Put_Owner(Parent.Handle));
          CheckDSError(FVideoWindow.Put_WindowStyle(FWindowStyle Or WS_CHILD Or WS_CLIPSIBLINGS));
          CheckDSError(FVideoWindow.Put_WindowStyleEx(FWindowStyleEx));
          If FIsVideoWindowOwner Then CheckDSError(FVideoWindow.SetWindowPosition(0, 0, Self.Width, Self.Height))
          Else CheckDSError(FVideoWindow.SetWindowPosition(Self.Left, Self.Top, Self.Width, Self.Height));
          FIsFullScreen := False;
        End;
    End;

  If FWindowLess <> Nil Then FIsFullScreen := False;

  FFullScreen := Value;
End;

Function TVideoWindow.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  If IsEqualGUID(IID_IVMRWindowlessControl9, IID) And (FWindowLess <> Nil) Then Begin
    Result := S_OK;
    IunKnown(Obj) := FWindowLess;
    Exit;
  End;
  Result := Inherited QueryInterface(IID, Obj);
  If Failed(Result) And Assigned(FBaseFilter) Then Result := FBaseFilter.QueryInterface(IID, Obj);
End;

Procedure TVideoWindow.GraphEvent(Event, Param1, Param2: Integer);
Begin
  Case Event Of
    EC_PALETTE_CHANGED: If FVideoWindow <> Nil Then Begin
        SetFullScreen(FFullScreen);
        If Name <> '' Then CheckDSError(FVideoWindow.Put_Caption(Name));
        CheckDSError(FVideoWindow.Put_MessageDrain(Handle));
      End;
    EC_VMR_RENDERDEVICE_SET: Begin
        If (FVMROptions.FMode = VmrWindowed) And (FVideoWindow <> Nil) Then Begin
          If Name <> '' Then CheckDSError(FVideoWindow.Put_Caption(Name));
          CheckDSError(FVideoWindow.Put_MessageDrain(Handle));
        End;
      End;
  End;
End;

Function TVideoWindow.CheckInputPinsConnected: Boolean;
Var
  PinList: TPinList;
  I: Integer;
Begin
  Result := False;
  If (FBaseFilter = Nil) Then Exit;
  PinList := TPinList.Create(FBaseFilter);
  Try
    For I := 0 To PinList.Count - 1 Do
      If PinList.Connected[I] Then Begin
        Result := True;
        Break;
      End;
  Finally
    PinList.Free;
  End;
End;

Procedure TVideoWindow.ControlEvent(Event: TControlEvent; Param: Integer = 0);
Var
  FilterInfo: TFilterInfo;
  FilterList: TFilterList;
  I: Integer;
  GUID: TGUID;
Begin
  Case Event Of
    CeDVDRendered: // mean our Video Filter have been removed
      Begin
        ZeroMemory(@FilterInfo, SizeOf(TFilterInfo));
        CheckDSError(FBaseFilter.QueryFilterInfo(FilterInfo));
        If Not Assigned(FilterInfo.PGraph) Then Begin
          FilterList := TFilterList.Create(FilterGraph.FFilterGraph);
          If FilterList.Count > 0 Then
            For I := 0 To FilterList.Count - 1 Do Begin
              FilterList.Items[I].GetClassID(GUID);
              If ISEqualGUID(GUID, CLSID_VideoRenderer) And (Mode = VmNormal) Then Begin
                FBaseFilter := Nil;
                FVideoWindow := Nil;
                FWindowLess := Nil;
                FBaseFilter := FilterList.Items[I];
                FBaseFilter.QueryInterface(IVideoWindow, FVideoWindow);
                Break;
              End;
            End;
        End;
      End;
    CePlay: Begin
        If CheckInputPinsConnected Then Begin
          Case FMode Of
            VmNormal: If FVideoWindow <> Nil Then Begin
                SetFullScreen(FFullScreen);
                If Name <> '' Then CheckDSError(FVideoWindow.Put_Caption(Name));
                CheckDSError(FVideoWindow.Put_MessageDrain(Handle));
              End;
            VmVMR: SetFullScreen(FFullScreen);
          End;
        End;
      End;

  End;
End;

Procedure TVideoWindow.WndProc(Var Message: TMessage);
Begin
  If ((Message.Msg = WM_CONTEXTMENU) And FullScreen) Then Begin
    If Assigned(PopupMenu) Then
      If PopupMenu.AutoPopup Then Begin
        PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
        Message.Result := 1;
      End;
  End
  Else Inherited WndProc(Message);
End;

Procedure TVideoWindow.SetTopMost(TopMost: Boolean);
Begin
  FTopMost := TopMost;
  If FFullScreen Then SetFullScreen(True);
End;

Procedure TVideoWindow.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Begin
  If FIsFullScreen Then Inherited MouseDown(Button, Shift, Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else Inherited MouseDown(Button, Shift, X, Y)
End;

Procedure TVideoWindow.MouseMove(Shift: TShiftState; X, Y: Integer);
Begin
  If Fisfullscreen Then Inherited MouseMove(Shift, Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else Inherited MouseMove(Shift, X, Y)
End;

Procedure TVideoWindow.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Begin
  If Fisfullscreen Then Inherited MouseUp(Button, Shift, Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else Inherited MouseUp(Button, Shift, X, Y)
End;

Function TVideoWindow.VMRGetBitMap(Stream: TStream): Boolean;
Var
  Image: PBitmapInfoHeader;
  BFH: TBITMAPFILEHEADER;
  Function DibSize: Cardinal;
  Begin
    Result := (Image.BiSize + Image.BiSizeImage + Image.BiClrUsed * Sizeof(TRGBQUAD));
  End;
  Function DibNumColors: Cardinal;
  Begin
    If (Image.BiClrUsed = 0) And (Image.BiBitCount <= 8) Then Result := 1 Shl Integer(Image.BiBitCount)
    Else Result := Image.BiClrUsed;
  End;
  Function DibPaletteSize: Cardinal;
  Begin
    Result := (DibNumColors * Sizeof(TRGBQUAD))
  End;

Begin
  Assert(Assigned(Stream));
  Result := False;
  If FWindowLess <> Nil Then
    If Succeeded(FWindowLess.GetCurrentImage(PByte(Image))) Then Begin
      BFH.BfType := $4D42; // BM
      BFH.BfSize := DibSize + Sizeof(TBITMAPFILEHEADER);
      BFH.BfReserved1 := 0;
      BFH.BfReserved2 := 0;
      BFH.BfOffBits := Sizeof(TBITMAPFILEHEADER) + Image.BiSize + DibPaletteSize;
      Stream.Write(BFH, SizeOf(TBITMAPFILEHEADER));
      Stream.Write(Image^, BFH.BfSize);
      Stream.Position := 0;
      CoTaskMemFree(Image);
      Result := True;
    End;
End;

Function TVideoWindow.GetVisible: Boolean;
Begin
  Result := Inherited Visible;
End;

Procedure TVideoWindow.SetVisible(Vis: Boolean);
Begin
  Inherited Visible := Vis;
  If Assigned(FVideoWindow) Then CheckDSError(FVideoWindow.Put_Visible(Vis));
End;

Procedure TVideoWindow.SetAllocator(Allocator: TAbstractAllocatorClass; UserID: Cardinal);
Begin
  FAllocatorClass := Allocator;
  FRenderLessUserID := UserID;
End;

// *****************************************************************************
// TSampleGrabber
// *****************************************************************************

Procedure TSampleGrabber.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then FFilterGraph.RemoveFilter(Self);
  If AFilterGraph <> Nil Then AFilterGraph.InsertFilter(Self);
  FFilterGraph := AFilterGraph;
End;

Function TSampleGrabber.GetFilter: IBaseFilter;
Begin
  Result := FBaseFilter;
End;

Function TSampleGrabber.GetName: String;
Begin
  Result := Name;
End;

Procedure TSampleGrabber.NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
Var
  EnumPins: IEnumPins;
Begin
  Case Operation Of
    FoAdding: Cocreateinstance(CLSID_SampleGrabber, Nil, CLSCTX_INPROC, IID_IBASEFilter, FBaseFilter);
    FoAdded: Begin
        FBaseFilter.QueryInterface(IID_ISampleGrabber, SampleGrabber);
        FBaseFilter.EnumPins(EnumPins);
        EnumPins.Next(1, InPutPin, Nil);
        EnumPins.Next(1, OutPutPin, Nil);
        EnumPins := Nil;
        UpdateMediaType;
        SampleGrabber.SetBufferSamples(True);
        SampleGrabber.SetCallback(Self, 1);
      End;
    FoRemoving: Begin
        FBaseFilter.Stop;
        InPutPin.Disconnect;
        OutPutPin.Disconnect;
      End;
    FoRemoved: Begin
        SampleGrabber.SetCallback(Nil, 1);
        SampleGrabber.SetBufferSamples(False);
        FBaseFilter := Nil;
        SampleGrabber := Nil;
        InPutPin := Nil;
        OutPutPin := Nil;
      End;
    FoRefresh: UpdateMediaType;
  End;
End;

Constructor TSampleGrabber.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FCriticalSection := TCriticalSection.Create;
  Assert(CheckFilter, 'The SampleGrabber Filter is not available on this system.');
  FMediaType := TMediaType.Create(MEDIATYPE_Video);
  FMediaType.SubType := MEDIASUBTYPE_RGB24;
  FMediaType.FormatType := FORMAT_VideoInfo;
  // [pjh, 2003-07-14] BMPInfo local
  // new(BMPInfo);
End;

Destructor TSampleGrabber.Destroy;
Begin
  FilterGraph := Nil;
  FMediaType.Free;
  // [pjh, 2003-07-14] BMPInfo local
  // Dispose(BMPInfo);
  FCriticalSection.Free;
  Inherited Destroy;
End;

Class Function TSampleGrabber.CheckFilter: Boolean;
Var
  AFilter: IBaseFilter;
Begin
  Result := Cocreateinstance(CLSID_SampleGrabber, Nil, CLSCTX_INPROC, IID_IBASEFilter, AFilter) = S_OK;
  AFilter := Nil;
End;

Procedure TSampleGrabber.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then FFilterGraph := Nil;
End;

Procedure TSampleGrabber.UpdateMediaType;
Begin
  If Assigned(SampleGrabber) Then Begin
    FBaseFilter.Stop;
    InPutPin.Disconnect;
    SampleGrabber.SetMediaType(MediaType.AMMediaType^);
  End;
End;

Procedure TSampleGrabber.SetBMPCompatible(Source: PAMMediaType; SetDefault: Cardinal);
Var
  SubType: TGUID;
  BitCount: LongWord;
Begin
  BitCount := SetDefault;
  MediaType.ResetFormatBuffer;
  ZeroMemory(MediaType.AMMediaType, Sizeof(TAMMediaType));
  MediaType.Majortype := MEDIATYPE_Video;
  MediaType.Formattype := FORMAT_VideoInfo;
  If Source = Nil Then Begin
    Case SetDefault Of
      0: MediaType.Subtype := MEDIASUBTYPE_RGB24;
      1: MediaType.Subtype := MEDIASUBTYPE_RGB1;
      2 .. 4: MediaType.Subtype := MEDIASUBTYPE_RGB4;
      5 .. 8: MediaType.Subtype := MEDIASUBTYPE_RGB8;
      9 .. 16: MediaType.Subtype := MEDIASUBTYPE_RGB555;
      17 .. 24: MediaType.Subtype := MEDIASUBTYPE_RGB24;
      25 .. 32: MediaType.Subtype := MEDIASUBTYPE_RGB32
    Else MediaType.Subtype := MEDIASUBTYPE_RGB32;
    End;
    UpdateMediaType;
    Exit;
  End;

  SubType := Source.Subtype;
  If (IsEqualGUID(SubType, MEDIASUBTYPE_RGB1) Or IsEqualGUID(SubType, MEDIASUBTYPE_RGB4) Or IsEqualGUID(SubType, MEDIASUBTYPE_RGB8) Or IsEqualGUID(SubType, MEDIASUBTYPE_RGB555) Or IsEqualGUID(SubType, MEDIASUBTYPE_RGB24) Or IsEqualGUID(SubType, MEDIASUBTYPE_RGB32)) Then MediaType.Subtype := SubType // no change
  Else Begin
    // get bitcount
    If Assigned(Source.PbFormat) Then
      If IsEqualGUID(Source.Formattype, FORMAT_VideoInfo) Then BitCount := PVideoInfoHeader(Source.PbFormat)^.BmiHeader.BiBitCount
      Else If IsEqualGUID(Source.Formattype, FORMAT_VideoInfo2) Then BitCount := PVideoInfoHeader2(Source.PbFormat)^.BmiHeader.BiBitCount
      Else If IsEqualGUID(Source.Formattype, FORMAT_MPEGVideo) Then BitCount := PMPEG1VideoInfo(Source.PbFormat)^.Hdr.BmiHeader.BiBitCount
      Else If IsEqualGUID(Source.Formattype, FORMAT_MPEG2Video) Then BitCount := PMPEG2VideoInfo(Source.PbFormat)^.Hdr.BmiHeader.BiBitCount;
    Case BitCount Of
      0: MediaType.Subtype := MEDIASUBTYPE_RGB24;
      1: MediaType.Subtype := MEDIASUBTYPE_RGB1;
      2 .. 4: MediaType.Subtype := MEDIASUBTYPE_RGB4;
      5 .. 8: MediaType.Subtype := MEDIASUBTYPE_RGB8;
      9 .. 16: MediaType.Subtype := MEDIASUBTYPE_RGB555;
      17 .. 24: MediaType.Subtype := MEDIASUBTYPE_RGB24;
      25 .. 32: MediaType.Subtype := MEDIASUBTYPE_RGB32
    Else MediaType.Subtype := MEDIASUBTYPE_RGB32;
    End;
  End;
  UpdateMediaType;
End;

Function GetDIBLineSize(BitCount, Width: Integer): Integer;
Begin
  If BitCount = 15 Then BitCount := 16;
  Result := ((BitCount * Width + 31) Div 32) * 4;
End;

// [pjh, 2003-07-17] modified
// Buffer =  Nil -> Get the data from SampleGrabber
// Buffer <> Nil -> Copy the DIB from buffer to Bitmap
Function TSampleGrabber.GetBitmap(Bitmap: TBitmap; Buffer: Pointer; BufferLen: Integer): Boolean;
Var
  Hr: HRESULT;
  BIHeaderPtr: PBitmapInfoHeader;
  MediaType: TAMMediaType;
  BitmapHandle: HBitmap;
  DIBPtr: Pointer;
  DIBSize: LongInt;
Begin
  Result := False;
  If Not Assigned(Bitmap) Then Exit;
  If Assigned(Buffer) And (BufferLen = 0) Then Exit;
  Hr := SampleGrabber.GetConnectedMediaType(MediaType);
  If Hr <> S_OK Then Exit;
  Try
    If IsEqualGUID(MediaType.Majortype, MEDIATYPE_Video) Then Begin
      BIHeaderPtr := Nil;
      If IsEqualGUID(MediaType.Formattype, FORMAT_VideoInfo) Then Begin
        If MediaType.CbFormat = SizeOf(TVideoInfoHeader) Then // check size
            BIHeaderPtr := @(PVideoInfoHeader(MediaType.PbFormat)^.BmiHeader);
      End Else If IsEqualGUID(MediaType.Formattype, FORMAT_VideoInfo2) Then Begin
        If MediaType.CbFormat = SizeOf(TVideoInfoHeader2) Then // check size
            BIHeaderPtr := @(PVideoInfoHeader2(MediaType.PbFormat)^.BmiHeader);
      End;
      // check, whether format is supported by TSampleGrabber
      If Not Assigned(BIHeaderPtr) Then Exit;
      BitmapHandle := CreateDIBSection(0, PBitmapInfo(BIHeaderPtr)^, DIB_RGB_COLORS, DIBPtr, 0, 0);
      If BitmapHandle <> 0 Then Begin
        Try
          If DIBPtr = Nil Then Exit;
          // get DIB size
          DIBSize := BIHeaderPtr^.BiSizeImage;
          If DIBSize = 0 Then Begin
            With BIHeaderPtr^ Do DIBSize := GetDIBLineSize(BiBitCount, BiWidth) * BiHeight * BiPlanes;
          End;
          // copy DIB
          If Not Assigned(Buffer) Then Begin
            // get buffer size
            BufferLen := 0;
            Hr := SampleGrabber.GetCurrentBuffer(BufferLen, Nil);
            If (Hr <> S_OK) Or (BufferLen <= 0) Then Exit;
            // copy buffer to DIB
            If BufferLen > DIBSize Then // copy Min(BufferLen, DIBSize)
                BufferLen := DIBSize;
            Hr := SampleGrabber.GetCurrentBuffer(BufferLen, DIBPtr);
            If Hr <> S_OK Then Exit;
          End Else Begin
            If BufferLen > DIBSize Then // copy Min(BufferLen, DIBSize)
                BufferLen := DIBSize;
            Move(Buffer^, DIBPtr^, BufferLen);
          End;
          Bitmap.Handle := BitmapHandle;
          Result := True;
        Finally
          If Bitmap.Handle <> BitmapHandle Then // preserve for any changes in Graphics.pas
              DeleteObject(BitmapHandle);
        End;
      End;
    End;
  Finally
    FreeMediaType(@MediaType);
  End;
End;

Function TSampleGrabber.GetBitmap(Bitmap: TBitmap): Boolean;
Begin
  Result := GetBitmap(Bitmap, Nil, 0);
End;

Function TSampleGrabber.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  Result := Inherited QueryInterface(IID, Obj);
  If Failed(Result) And Assigned(FBaseFilter) Then Result := FBaseFilter.QueryInterface(IID, Obj);
End;

Function TSampleGrabber.BufferCB(SampleTime: Double; PBuffer: PByte; BufferLen: Integer): HResult;
Begin
  If Assigned(FOnBuffer) Then Begin
    FCriticalSection.Enter;
    Try
      FOnBuffer(Self, SampleTime, PBuffer, BufferLen);
    Finally
      FCriticalSection.Leave;
    End;
  End;
  Result := S_OK;
End;

Function TSampleGrabber.SampleCB(SampleTime: Double; PSample: IMediaSample): HResult;
Begin
  Result := S_OK;
End;

// *****************************************************************************
// TFilter
// *****************************************************************************

Function TFilter.GetFilter: IBaseFilter;
Begin
  Result := FFilter;
End;

Function TFilter.GetName: String;
Begin
  Result := Name;
End;

Procedure TFilter.NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
Var
  State: TFilterState;
Begin
  Case Operation Of
    FoAdding: FFilter := BaseFilter.CreateFilter;
    FoRemoving: If (FFilter <> Nil) And (FFilter.GetState(0, State) = S_OK) Then
        Case State Of
          State_Paused, State_Running: FFilter.Stop;
        End;
    FoRemoved: FFilter := Nil;
    FoRefresh: If Assigned(FFilterGraph) Then Begin
        FFilterGraph.RemoveFilter(Self);
        FFilterGraph.InsertFilter(Self);
      End;
  End;
End;

Constructor TFilter.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FBaseFilter := TBaseFilter.Create;
End;

Destructor TFilter.Destroy;
Begin
  FBaseFilter.Free;
  FilterGraph := Nil;
  Inherited Destroy;
End;

Procedure TFilter.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then FFilterGraph.RemoveFilter(Self);
  If AFilterGraph <> Nil Then AFilterGraph.InsertFilter(Self);
  FFilterGraph := AFilterGraph;
End;

Procedure TFilter.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then FFilterGraph := Nil;
End;

Function TFilter.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  Result := Inherited QueryInterface(IID, Obj);
  If Not Succeeded(Result) Then
    If Assigned(FFilter) Then Result := FFilter.QueryInterface(IID, Obj);
End;

// *****************************************************************************
// TASFWriter
// *****************************************************************************

Constructor TASFWriter.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FAutoIndex := True;
  FMultiPass := False;
  FDontCompress := False;
End;

Destructor TASFWriter.Destroy;
Begin
  FilterGraph := Nil;
  Inherited Destroy;
End;

Procedure TASFWriter.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then FFilterGraph.RemoveFilter(Self);
  If AFilterGraph <> Nil Then AFilterGraph.InsertFilter(Self);
  FFilterGraph := AFilterGraph;
End;

Function TASFWriter.GetFilter: IBaseFilter;
Begin
  Result := FFilter;
End;

Function TASFWriter.GetName: String;
Begin
  Result := Name;
End;

Procedure TASFWriter.NotifyFilter(Operation: TFilterOperation; Param: Integer = 0);
Var
  PinList: TPinList;
  ServiceProvider: IServiceProvider;
  FAsfConfig: IConfigAsfWriter2;
Begin
  Case Operation Of
    FoAdding: Cocreateinstance(CLSID_WMAsfWriter, Nil, CLSCTX_INPROC, IBaseFilter, FFilter);
    FoAdded: Begin
        If Assigned(FFilter) Then Begin
          SetProfile(FProfile);
          SetFileName(FFileName);
          If Succeeded(FFilter.QueryInterface(IID_IConfigAsfWriter2, FAsfConfig)) Then Begin
            FAsfConfig.SetParam(AM_CONFIGASFWRITER_PARAM_AUTOINDEX, Cardinal(FAutoIndex), 0);
            FAsfConfig.SetParam(AM_CONFIGASFWRITER_PARAM_MULTIPASS, Cardinal(FMultiPass), 0);
            FAsfConfig.SetParam(AM_CONFIGASFWRITER_PARAM_DONTCOMPRESS, Cardinal(FDontCompress), 0);
          End;

          PinList := TPinList.Create(FFilter);
          Try
            If PinList.Count >= 1 Then Begin
              AudioInput := PinList.Items[0];
              If PinList.Count = 2 Then Begin
                VideoInput := PinList.Items[1];
                VideoInput.QueryInterface(IID_IAMStreamConfig, VideoStreamConfig);
              End;
              AudioInput.QueryInterface(IID_IAMStreamConfig, AudioStreamConfig);
              If Succeeded(QueryInterface(IServiceProvider, ServiceProvider)) Then Begin
                ServiceProvider.QueryService(IID_IWMWriterAdvanced2, IID_IWMWriterAdvanced2, WriterAdvanced2);
                ServiceProvider := Nil;
              End;
              If ((FPort > 0) And (FMaxUsers > 0)) Then
                If Succeeded(WMCreateWriterNetworkSink(WriterNetworkSink)) Then Begin
                  WriterNetworkSink.SetNetworkProtocol(WMT_PROTOCOL_HTTP);
                  WriterNetworkSink.SetMaximumClients(FMaxUsers);
                  WriterNetworkSink.Open(FPort);
                  WriterAdvanced2.AddSink(WriterNetworkSink);
                End;
            End;
          Finally
            PinList.Free;
          End;

        End;
      End;
    FoRemoving: Begin
        If Assigned(FFilter) Then FFilter.Stop;
        If Assigned(WriterNetworkSink) Then Begin
          WriterNetworkSink.Disconnect;
          WriterNetworkSink.Close;
        End;
        If Assigned(AudioInput) Then AudioInput.Disconnect;
        If Assigned(VideoInput) Then VideoInput.Disconnect;
      End;

    FoRemoved: Begin
        WriterAdvanced2 := Nil;
        WriterNetworkSink := Nil;
        AudioInput := Nil;
        VideoInput := Nil;
        AudioStreamConfig := Nil;
        VideoStreamConfig := Nil;
        FFilter := Nil;
      End;
  End;
End;

Procedure TASFWriter.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then FFilterGraph := Nil;
End;

Function TASFWriter.GetProfile: TWMPofiles8;
Var
  GUIDProf: TGUID;
  ConfigAsfWriter: IConfigAsfWriter;
Begin
  If Succeeded(QueryInterface(IConfigAsfWriter, ConfigAsfWriter)) Then Begin
    ConfigAsfWriter.GetCurrentProfileGuid(GUIDProf);
    Result := ProfileFromGUID(GUIDProf);
    ConfigAsfWriter := Nil;
  End
  Else Result := FProfile
End;

Procedure TASFWriter.SetProfile(Profile: TWMPofiles8);
Var
  ConfigAsfWriter: IConfigAsfWriter;
Begin
  If Succeeded(QueryInterface(IConfigAsfWriter, ConfigAsfWriter)) Then Begin
    ConfigAsfWriter.ConfigureFilterUsingProfileGuid(WMProfiles8[Profile]);
    ConfigAsfWriter := Nil;
  End
  Else FProfile := Profile;
End;

Function TASFWriter.GetFileName: String;
Var
  F: PWideChar;
  FileSinkFilter2: IFileSinkFilter2;
Begin
  If Succeeded(QueryInterface(IFileSinkFilter2, FileSinkFilter2)) Then Begin
    FileSinkFilter2.GetCurFile(F, Nil);
    FileSinkFilter2 := Nil;
    Result := F;
  End
  Else Result := FFileName;
End;

Procedure TASFWriter.SetFileName(FileName: String);
Var
  FileSinkFilter2: IFileSinkFilter2;
Begin
  FFileName := FileName;
  If Succeeded(QueryInterface(IFileSinkFilter2, FileSinkFilter2)) Then Begin
    FileSinkFilter2.SetFileName(PWideChar(FFileName), Nil);
    FileSinkFilter2 := Nil;
  End;
End;

Function TASFWriter.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  Result := Inherited QueryInterface(IID, Obj);
  If Failed(Result) And Assigned(FFilter) Then Result := FFilter.QueryInterface(IID, Obj);
End;

// *****************************************************************************
// TDSTrackBar
// *****************************************************************************

Procedure TDSTrackBar.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then FFilterGraph.RemoveEventNotifier(Self);
  If AFilterGraph <> Nil Then AFilterGraph.InsertEventNotifier(Self);
  FFilterGraph := AFilterGraph;
End;

Constructor TDSTrackBar.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  FMouseDown := False;
  FEnabled := False;
  FInterval := 1000;
  FWindowHandle := AllocateHWnd(TimerWndProc);
End;

Destructor TDSTrackBar.Destroy;
Begin
  FEnabled := False;
  UpdateTimer;
  FilterGraph := Nil;
  DeallocateHWnd(FWindowHandle);
  FMediaSeeking := Nil;
  Inherited Destroy;
End;

Procedure TDSTrackBar.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then Begin
    FMediaSeeking := Nil;
    FFilterGraph := Nil;
  End;
End;

Procedure TDSTrackBar.GraphEvent(Event, Param1, Param2: Integer);
Var
  Duration: Int64;
  Zero: Int64;
Begin
  Case Event Of
    EC_CLOCK_CHANGED: If Assigned(FMediaSeeking) Then Begin
        Zero := 0;
        FMediaSeeking.GetDuration(Duration);
        FMediaSeeking.SetPositions(Zero, AM_SEEKING_AbsolutePositioning, Duration, AM_SEEKING_NoPositioning);
      End;
  End;
End;

Procedure TDSTrackBar.ControlEvent(Event: TControlEvent; Param: Integer = 0);
Begin
  Case Event Of
    CePlay: TimerEnabled := Enabled;
    CePause .. CeStop: TimerEnabled := False;
    CeActive: Case Param Of
        0: FMediaSeeking := Nil;
        1: FFilterGraph.QueryInterface(IMediaSeeking, FMediaSeeking);
      End;
  End;
End;

Procedure TDSTrackBar.SetTimerEnabled(Value: Boolean);
Begin
  If Value <> FEnabled Then Begin
    FEnabled := Value;
    UpdateTimer;
  End;
End;

Procedure TDSTrackBar.SetInterval(Value: Cardinal);
Begin
  If Value <> FInterval Then Begin
    FInterval := Value;
    UpdateTimer;
  End;
End;

Procedure TDSTrackBar.SetOnTimer(Value: TTimerEvent);
Begin
  FOnTimer := Value;
  UpdateTimer;
End;

Procedure TDSTrackBar.UpdateTimer;
Begin
  KillTimer(FWindowHandle, 1);
  If (FInterval <> 0) And FEnabled Then
    If SetTimer(FWindowHandle, 1, FInterval, Nil) = 0 Then Raise EOutOfResources.Create(SNoTimers);
End;

Procedure TDSTrackBar.Timer;
Var
  CurrentPos, StopPos: Int64;
  MlsCurrentPos, MlsStopPos: Cardinal;
Begin
  If Assigned(FMediaSeeking) And (Not FMouseDown) Then
    If Succeeded(FMediaSeeking.GetDuration(StopPos)) Then
      If Succeeded(FMediaSeeking.GetCurrentPosition(CurrentPos)) Then Begin
        MlsCurrentPos := RefTimeToMiliSec(CurrentPos);
        MlsStopPos := RefTimeToMiliSec(StopPos);
        Min := 0;
        Max := MlsStopPos Div TimerInterval;
        Position := MlsCurrentPos Div TimerInterval;
        If Assigned(FOnTimer) Then FOnTimer(Self, MlsCurrentPos, MlsStopPos);
      End;
End;

Procedure TDSTrackBar.TimerWndProc(Var Msg: TMessage);
Begin
  With Msg Do
    If Msg = WM_TIMER Then
      Try
        Timer;
      Except
        Application.HandleException(Self);
      End
    Else Result := DefWindowProc(FWindowHandle, Msg, WParam, LParam);
End;

Procedure TDSTrackBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  StopPosition, CurrentPosition: Int64;
Begin
  Inherited MouseUp(Button, Shift, X, Y);
  If Button = MbLeft Then
    If Assigned(FMediaSeeking) Then Begin
      FMediaSeeking.GetStopPosition(StopPosition);
      CurrentPosition := (StopPosition * Position) Div Max;
      FMediaSeeking.SetPositions(CurrentPosition, AM_SEEKING_AbsolutePositioning, StopPosition, AM_SEEKING_NoPositioning);

    End;
  FMouseDown := False;
End;

Procedure TDSTrackBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Begin
  Inherited MouseDown(Button, Shift, X, Y);
  If Button = MbLeft Then FMouseDown := True;
End;

// --------------------------- Color Control -------------------------------
Constructor TColorControl.Create(AOwner: TDSVideoWindowEx2);
Begin
  Inherited Create;
  FOwner := AOwner;
  ZeroMemory(@FDefault, SizeOf(TDDColorControl));
  With FDefault Do Begin
    DwSize := SizeOf(TDDCOLORCONTROL);
    DwFlags := DDCOLOR_BRIGHTNESS Or DDCOLOR_CONTRAST Or DDCOLOR_HUE Or DDCOLOR_SATURATION Or DDCOLOR_GAMMA Or DDCOLOR_SHARPNESS Or DDCOLOR_COLORENABLE;
    LBrightness := 750;
    LContrast := 10000;
    LGamma := 1;
    LHue := 0;
    LSaturation := 10000;
    LSharpness := 5;
    LColorEnable := Integer(True);
    DwReserved1 := 0;
  End;
  FBrightness := FDefault.LBrightness;
  FContrast := FDefault.LContrast;
  FGamma := FDefault.LGamma;
  FHue := FDefault.LHue;
  FSaturation := FDefault.LSaturation;
  FSharpness := FDefault.LSharpness;
  FUtilColor := Bool(FDefault.LColorEnable);
End;

Procedure TColorControl.ReadDefault;
Var
  EnumPins: IEnumPins;
  Pin: IPin;
  Ul: Cardinal;
  Pd: TPinDirection;
  MPC: IMixerPinConfig2;
  Tel: Integer;
  FG: IFilterGraph;
  FilterList: TFilterList;
  Hr: HResult;
  OVM: IBaseFilter;
  FClass: TGuid;
  Tmp: TDDColorControl;
Begin
  If (CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState) Or (TDSVideoWindowEx2(FOwner).FFilterGraph = Nil) Or (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = False) Then Exit;

  MPC := Nil;
  OVM := Nil;
  FG := Nil;
  FG := TDSVideoWindowEx2(FOwner).FFilterGraph.FFilterGraph;
  FilterList := TFilterList.Create(FG);
  Try
    For Tel := 0 To FilterList.Count - 1 Do Begin
      FilterList[Tel].GetClassID(FClass);
      If IsEqualGuid(FClass, CLSID_OverlayMixer) Then OVM := FilterList[Tel];
      If IsEqualGuid(FClass, CLSID_OverlayMixer2) Then OVM := FilterList[Tel];
    End;

    If OVM = Nil Then Exit;
    Hr := OVM.EnumPins(EnumPins);
    If Failed(Hr) Then Exit;

    Tel := 0;
    While (EnumPins.Next(1, Pin, @Ul) = S_OK) And (Ul = 1) And (Tel = 0) Do Begin
      Hr := Pin.QueryDirection(Pd);
      If Failed(Hr) Then Exit;

      If Pd = PINDIR_INPUT Then Begin
        Hr := Pin.QueryInterface(IID_IMixerPinConfig2, MPC);
        If Failed(Hr) Then Exit;
        Inc(Tel);
      End;
      Pin := Nil;
    End;
    EnumPins := Nil;

    ZeroMemory(@Tmp, SizeOf(TDDColorControl));
    Tmp.DwSize := SizeOf(TDDCOLORCONTROL);

    Hr := MPC.GetOverlaySurfaceColorControls(Tmp);
    If Failed(Hr) Then Exit;

    FDefault := Tmp;
  Finally
    FilterList.Free;
    FG := Nil;
    OVM := Nil;
    EnumPins := Nil;
    Pin := Nil;
    MPC := Nil;
  End;
End;

Procedure TColorControl.UpdateColorControls;
Var
  EnumPins: IEnumPins;
  Pin: IPin;
  Ul: Cardinal;
  Pd: TPinDirection;
  MPC: IMixerPinConfig2;
  Tel: Integer;
  FG: IFilterGraph;
  FilterList: TFilterList;
  Hr: HResult;
  OVM: IBaseFilter;
  FClass: TGuid;
  Tmp: TDDColorControl;
Begin
  If (CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState) Or (TDSVideoWindowEx2(FOwner).FFilterGraph = Nil) Or (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = False) Then Exit;

  MPC := Nil;
  OVM := Nil;
  FG := Nil;
  FG := TDSVideoWindowEx2(FOwner).FFilterGraph.FFilterGraph;
  FilterList := TFilterList.Create(FG);
  Try
    For Tel := 0 To FilterList.Count - 1 Do Begin
      FilterList[Tel].GetClassID(FClass);
      If IsEqualGuid(FClass, CLSID_OverlayMixer) Then OVM := FilterList[Tel];
      If IsEqualGuid(FClass, CLSID_OverlayMixer2) Then OVM := FilterList[Tel];
    End;

    If OVM = Nil Then Exit;
    Hr := OVM.EnumPins(EnumPins);
    If Failed(Hr) Then Exit;

    Tel := 0;
    While (EnumPins.Next(1, Pin, @Ul) = S_OK) And (Ul = 1) And (Tel = 0) Do Begin
      Hr := Pin.QueryDirection(Pd);
      If Failed(Hr) Then Exit;

      If Pd = PINDIR_INPUT Then Begin
        Hr := Pin.QueryInterface(IID_IMixerPinConfig2, MPC);
        If Failed(Hr) Then Exit;
        Inc(Tel);
      End;
      Pin := Nil;
    End;
    EnumPins := Nil;

    Tmp.DwSize := SizeOf(TDDCOLORCONTROL);
    Tmp.DwFlags := DDCOLOR_BRIGHTNESS Or DDCOLOR_CONTRAST Or DDCOLOR_HUE Or DDCOLOR_SATURATION Or DDCOLOR_GAMMA Or DDCOLOR_SHARPNESS Or DDCOLOR_COLORENABLE;
    Tmp.LBrightness := FBrightness;
    Tmp.LContrast := FContrast;
    Tmp.LHue := FHue;
    Tmp.LSaturation := FSaturation;
    Tmp.LSharpness := FSharpness;
    Tmp.LGamma := FGamma;
    Tmp.LColorEnable := Integer(FUtilColor);
    Tmp.DwReserved1 := 0;

    Hr := MPC.SetOverlaySurfaceColorControls(Pointer(@Tmp));
    If Failed(Hr) Then Exit;
  Finally
    FilterList.Free;
    FG := Nil;
    OVM := Nil;
    EnumPins := Nil;
    Pin := Nil;
    MPC := Nil;
  End;
End;

Procedure TColorControl.GetColorControls;
Var
  EnumPins: IEnumPins;
  Pin: IPin;
  Ul: Cardinal;
  Pd: TPinDirection;
  MPC: IMixerPinConfig2;
  Tel: Integer;
  FG: IFilterGraph;
  FilterList: TFilterList;
  Hr: HResult;
  OVM: IBaseFilter;
  FClass: TGuid;
  Tmp: TDDColorControl;
Begin
  If (CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState) Or (TDSVideoWindowEx2(FOwner).FFilterGraph = Nil) Or (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = False) Then Exit;

  MPC := Nil;
  OVM := Nil;
  FG := Nil;
  FG := TDSVideoWindowEx2(FOwner).FFilterGraph.FFilterGraph;
  FilterList := TFilterList.Create(FG);
  Try
    For Tel := 0 To FilterList.Count - 1 Do Begin
      FilterList[Tel].GetClassID(FClass);
      If IsEqualGuid(FClass, CLSID_OverlayMixer) Then OVM := FilterList[Tel];
      If IsEqualGuid(FClass, CLSID_OverlayMixer2) Then OVM := FilterList[Tel];
    End;

    If OVM = Nil Then Exit;
    Hr := OVM.EnumPins(EnumPins);
    If Failed(Hr) Then Exit;

    Tel := 0;
    While (EnumPins.Next(1, Pin, @Ul) = S_OK) And (Ul = 1) And (Tel = 0) Do Begin
      Hr := Pin.QueryDirection(Pd);
      If Failed(Hr) Then Exit;

      If Pd = PINDIR_INPUT Then Begin
        Hr := Pin.QueryInterface(IID_IMixerPinConfig2, MPC);
        If Failed(Hr) Then Exit;
        Inc(Tel);
      End;
      Pin := Nil;
    End;
    EnumPins := Nil;

    ZeroMemory(@Tmp, SizeOf(TDDColorControl));
    Tmp.DwSize := SizeOf(TDDCOLORCONTROL);

    Hr := MPC.GetOverlaySurfaceColorControls(Tmp);
    If Failed(Hr) Then Begin
      FBrightness := 750;
      FContrast := 10000;
      FHue := 0;
      FSaturation := 10000;
      FSharpness := 5;
      FGamma := 1;
      FUtilColor := True;
      Exit;
    End Else Begin
      FBrightness := Tmp.LBrightness;
      FContrast := Tmp.LContrast;
      FHue := Tmp.LHue;
      FSaturation := Tmp.LSaturation;
      FSharpness := Tmp.LSharpness;
      FGamma := Tmp.LGamma;
      FUtilColor := Bool(Tmp.LColorEnable);
    End;
  Finally
    FilterList.Free;
    FG := Nil;
    OVM := Nil;
    EnumPins := Nil;
    Pin := Nil;
    MPC := Nil;
  End;
End;

Procedure TColorControl.RestoreDefault;
Begin
  FBrightness := FDefault.LBrightness;
  FContrast := FDefault.LContrast;
  FHue := FDefault.LHue;
  FSaturation := FDefault.LSaturation;
  FSharpness := FDefault.LSharpness;
  FGamma := FDefault.LGamma;
  FUtilColor := Bool(FDefault.LColorEnable);
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
End;

Procedure TColorControl.SetBrightness(Value: Integer);
Begin
  If (Value > -1) And (Value < 10001) Then Begin
    If Value <> FBrightness Then FBrightness := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between 0 -> 10.000', [Value]);
End;

Procedure TColorControl.SetContrast(Value: Integer);
Begin
  If (Value > -1) And (Value < 20001) Then Begin
    If Value <> FContrast Then FContrast := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between 0 -> 20.000', [Value]);
End;

Procedure TColorControl.SetHue(Value: Integer);
Begin
  If (Value > -181) And (Value < 182) Then Begin
    If Value <> FHue Then FHue := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between -180 -> 180', [Value]);
End;

Procedure TColorControl.SetSaturation(Value: Integer);
Begin
  If (Value > -1) And (Value < 20001) Then Begin
    If Value <> FSaturation Then FSaturation := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between 0 -> 20.000', [Value]);
End;

Procedure TColorControl.SetSharpness(Value: Integer);
Begin
  If (Value > -1) And (Value < 11) Then Begin
    If Value <> FSharpness Then FSharpness := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between 0 -> 10', [Value]);
End;

Procedure TColorControl.SetGamma(Value: Integer);
Begin
  If (Value > 0) And (Value < 501) Then Begin
    If Value <> FGamma Then FGamma := Value;
    If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
  End
  Else Raise Exception.CreateFmt('Value %d out of range. Value must bee between 1 -> 500', [Value]);
End;

Procedure TColorControl.SetUtilColor(Value: Boolean);
Begin
  FUtilColor := Value;
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then UpdateColorControls;
End;

Function TColorControl.GetBrightness: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FBrightness;
End;

Function TColorControl.GetContrast: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FContrast;
End;

Function TColorControl.GetHue: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FHue;
End;

Function TColorControl.GetSaturation: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FSaturation;
End;

Function TColorControl.GetSharpness: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FSharpness;
End;

Function TColorControl.GetGamma: Integer;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FGamma;
End;

Function TColorControl.GetUtilColor: Boolean;
Begin
  If (Not(CsDesigning In TDSVideoWindowEx2(FOwner).ComponentState)) And (TDSVideoWindowEx2(FOwner).FFilterGraph <> Nil) And (TDSVideoWindowEx2(FOwner).FFilterGraph.Active = True) Then GetColorControls;
  Result := FUtilColor;
End;

// ---------------------- DSVideoWindowEx2Capabilities -------------------

Constructor TDSVideoWindowEx2Caps.Create(AOwner: TDSVideoWindowEx2);
Begin
  Inherited Create;
  Owner := AOwner;
End;

Function TDSVideoWindowEx2Caps.GetCanOverlay: Boolean;
Begin
  Result := TDSVideoWindowEx2(Owner).FOverlayMixer <> Nil;
End;

Function TDSVideoWindowEx2Caps.GetCanControlBrigtness: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_BRIGHTNESS = DDCOLOR_BRIGHTNESS
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlContrast: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_CONTRAST = DDCOLOR_CONTRAST
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlHue: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_HUE = DDCOLOR_HUE
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlSaturation: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_SATURATION = DDCOLOR_SATURATION
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlSharpness: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_SHARPNESS = DDCOLOR_SHARPNESS
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlGamma: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_GAMMA = DDCOLOR_GAMMA
  Else Result := False;
End;

Function TDSVideoWindowEx2Caps.GetCanControlUtilizedColor: Boolean;
Begin
  If TDSVideoWindowEx2(Owner).FColorControl <> Nil Then Result := TDSVideoWindowEx2(Owner).FColorControl.FDefault.DwFlags And DDCOLOR_COLORENABLE = DDCOLOR_COLORENABLE
  Else Result := False;
End;

// ----------------------------------- Overlay Callback ------------------

Constructor TOverlayCallBack.Create(Owner: TObject);
Begin
  AOwner := Owner;
End;

Function TOverlayCallback.OnUpdateOverlay(BBefore: BOOL; DwFlags: DWORD; BOldVisible: BOOL; Var PrcOldSrc, PrcOldDest: TRECT; BNewVisible: BOOL; Var PrcNewSrc, PrcNewDest: TRECT): HRESULT; Stdcall;
Begin
  Result := S_OK;
End;

Function TOverlayCallback.OnUpdateColorKey(Var PKey: TCOLORKEY; DwColor: DWORD): HRESULT; Stdcall;
Begin
  TDSVideoWindowEx2(AOwner).FColorKey := PKey.HighColorValue;
  If Assigned(TDSVideoWindowEx2(AOwner).FOnColorKey) Then TDSVideoWindowEx2(AOwner).FOnColorKey(Self);
  Result := S_OK;
End;

Function TOverlayCallback.OnUpdateSize(DwWidth, DwHeight, DwARWidth, DwARHeight: DWORD): HRESULT; Stdcall;
Begin
  If (AOwner = Nil) Then Begin
    Result := S_OK;
    Exit;
  End;
  TDSVideoWindowEx2(AOwner).GetVideoInfo;
  TDSVideoWindowEx2(AOwner).Clearback;
  Result := S_OK;
End;

// ------------------------------ DSVideoWindowEx -------------------------

Procedure TDSVideoWindowEx2.NotifyFilter(Operation: TFilterOperation; Param: Integer);
Var
  I: Integer;
  EnumPins: TPinList;
  PGB: IGraphBuilder;
Begin
  EnumPins := Nil;
  PGB := Nil;
  Try
    Case Operation Of
      FoAdding: Begin
          GraphWasUpdatet := False;
          CoCreateInstance(CLSID_VideoRenderer, Nil, CLSCTX_INPROC_SERVER, IID_IBaseFilter, FBaseFilter);
        End;
      FoAdded: Begin
          FBaseFilter.QueryInterface(IVideoWindow, FVideoWindow);
        End;
      FoRemoving: Begin
          If FOverlayMixer <> Nil Then Begin
            FColorControl.RestoreDefault;
            FBaseFilter.Stop;
            EnumPins := TPinList.Create(FOverlayMixer);
            If EnumPins.Count > 0 Then
              For I := 0 To EnumPins.Count - 1 Do EnumPins.Items[I].Disconnect;
          End;
          If FBaseFilter <> Nil Then Begin
            FBaseFilter.Stop;
            EnumPins := TPinList.Create(FBaseFilter);
            If EnumPins.Count > 0 Then
              For I := 0 To EnumPins.Count - 1 Do EnumPins.Items[I].Disconnect;
          End;
          If FDDXM <> Nil Then FDDXM.SetCallbackInterface(Nil, 0);
          If OverlayCallback <> Nil Then OverlayCallback := Nil;
        End;
      FoRemoved: Begin
          GraphWasUpdatet := False;
          FDDXM := Nil;
          FOverlayMixer := Nil;
          FVideoRenderer := Nil;
          FVideoWindow := Nil;
          FBaseFilter := Nil;
        End;
    End;
  Finally
    If EnumPins <> Nil Then EnumPins.Free;
    PGB := Nil;
  End;
End;

Procedure TDSVideoWindowEx2.GraphEvent(Event, Param1, Param2: Integer);
Begin
  Case Event Of
    EC_PALETTE_CHANGED: RefreshVideoWindow;
    EC_CLOCK_CHANGED: Begin
        If GraphBuildOk Then SetVideoZOrder;
        SetZoom(FZoom);
        SetAspectMode(FAspectMode);
        If GraphBuildOk Then ClearBack;
      End;

  End;
End;

Function TDSVideoWindowEx2.GetName: String;
Begin
  Result := Name;
End;

Procedure TDSVideoWindowEx2.ControlEvent(Event: TControlEvent; Param: Integer = 0);
Var
  FilterInfo: TFilterInfo;
  FilterList: TFilterList;
  I: Integer;
  GUID: TGUID;
  TmpName: UnicodeString;
Begin
  FilterList := Nil;
  Try
    Case Event Of
      CeDVDRendered: Begin // mean our Video Filter have been removed
          ZeroMemory(@FilterInfo, SizeOf(TFilterInfo));
          FBaseFilter.QueryFilterInfo(FilterInfo);
          If Not Assigned(FilterInfo.PGraph) Then Begin
            FilterList := TFilterList.Create(FilterGraph.FFilterGraph);
            If FilterList.Count > 0 Then
              For I := 0 To FilterList.Count - 1 Do Begin
                FilterList.Items[I].GetClassID(GUID);
                If ISEqualGUID(GUID, CLSID_VideoRenderer) Then Begin
                  FOverlayMixer := Nil;
                  FBaseFilter := Nil;
                  FVideoWindow := Nil;
                  FVideoRenderer := Nil;
                  FBaseFilter := FilterList.Items[I];
                  FBaseFilter.QueryInterface(IVideoWindow, FVideoWindow);
                  GraphBuildOk := Succeeded(UpdateGraph);
                  If GraphBuildOk Then Begin
                    FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
                    FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
                  End;
                  RefreshVideoWindow;
                  Break;
                End Else If ISEqualGUID(GUID, CLSID_VideoMixingRenderer) Then Begin
                  FOverlayMixer := Nil;
                  FBaseFilter := Nil;
                  FVideoRenderer := Nil;
                  TmpName := Name;
                  If FVideoWindow <> Nil Then FilterGraph.FFilterGraph.AddFilter(FVideoWindow As IBaseFilter, PWideChar(TmpName));
                  FBaseFilter := FVideoWindow As IBaseFilter;
                  GraphBuildOk := Succeeded(UpdateGraph);
                  If GraphBuildOk Then Begin
                    FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
                    FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
                  End;
                  RefreshVideoWindow;
                  Break;
                End;
              End;
          End;
        End;
      CePlay: Begin
          If Not GraphWasUpdatet Then Begin
            GraphBuildOk := Succeeded(UpdateGraph);
            If GraphBuildOk Then Begin
              FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
              FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
            End;
            RefreshVideoWindow;
          End;
          If GraphBuildOk Then Begin
            If (Not FOverlayVisible) And (Not FDesktopPlay) Then Begin
              FOverlayVisible := True;
              If Assigned(FOnOverlay) Then FOnOverlay(Self, True);
              Clearback;
            End;
          End;
        End;
      CePause: Begin
          If Not GraphWasUpdatet Then Begin
            GraphBuildOk := Succeeded(UpdateGraph);
            If GraphBuildOk Then Begin
              FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
              FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
            End;
            RefreshVideoWindow;
          End;
          If GraphBuildOk Then
            If (Not FOverlayVisible) And (Not FDesktopPlay) Then Begin
              FOverlayVisible := True;
              If Assigned(FOnOverlay) Then FOnOverlay(Self, True);
              Clearback;
            End;
        End;
      CeStop: Begin
          If Not GraphWasUpdatet Then Begin
            GraphBuildOk := Succeeded(UpdateGraph);
            If GraphBuildOk Then Begin
              FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
              FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
            End;
            RefreshVideoWindow;
          End;
          If GraphBuildOk Then
            If FOverlayVisible Then Begin
              FOverlayVisible := False;
              Clearback;
              If Assigned(FOnOverlay) Then FOnOverlay(Self, False);
            End;
        End;
      CeFileRendered: Begin
          GraphBuildOk := Succeeded(UpdateGraph);
          If GraphBuildOk Then Begin
            FColorControl.ReadDefault; // Read the Colorcontrols settings of the OverlayMixer.
            FColorControl.UpdateColorControls; // Apply our settings to the ColorControls.
          End;
          RefreshVideoWindow;
        End;
    End;
  Finally
    If FilterList <> Nil Then FilterList.Free;
  End;
End;

Procedure TDSVideoWindowEx2.RefreshVideoWindow;
Begin
  If FVideoWindow <> Nil Then
    With FVideoWindow Do Begin
      If FIsVideoWindowOwner Then Put_Owner(Handle)
      Else Put_Owner(Parent.Handle);
      Put_WindowStyle(FWindowStyle Or WS_CHILD Or WS_CLIPSIBLINGS);
      Put_WindowStyleEx(FWindowStyleEx);
      If FIsVideoWindowOwner Then FVideoWindow.SetWindowPosition(0, 0, Width, Height)
      Else FVideoWindow.SetWindowPosition(Left, Top, Width, Height);
      If Name <> '' Then Put_Caption(Name);
      Put_MessageDrain(Handle);
      Application.ProcessMessages;
      Put_AutoShow(Not FDesktopPlay);
    End;
End;

Function TDSVideoWindowEx2.GetFilter: IBaseFilter;
Begin
  Result := FBaseFilter;
End;

Constructor TDSVideoWindowEx2.Create(AOwner: TComponent);
Begin
  Inherited Create(AOwner);
  ControlStyle := [CsAcceptsControls, CsCaptureMouse, CsClickEvents, CsDoubleClicks, CsReflector];
  TabStop := True;
  Height := 240;
  Width := 320;
  Color := $000000;
  FColorKey := $100010; // clNone;
  FFullScreen := False;
  FColorControl := TColorControl.Create(Self);
  FCaps := TDSVideoWindowEx2Caps.Create(Self);
  AspectRatio := RmLetterBox;
  DigitalZoom := 0;
  GraphBuildOK := False;
  FNoScreenSaver := False;
  FIdleCursor := 0;
  If (CsDesigning In Componentstate) Then Exit;
  FFullScreenControl := TForm.Create(Nil);
  FFullScreenControl.Color := Color;
  FFullScreenControl.DefaultMonitor := DmDesktop;
  FFullScreenControl.BorderStyle := BsNone;
  FFullScreenControl.OnCloseQuery := FullScreenCloseQuery;
  FOldParent := Nil;
  FMonitor := Nil;
  FVideoWindowHandle := 0;
  GraphWasUpdatet := False;
  Application.OnIdle := MyIdleHandler;
End;

Destructor TDSVideoWindowEx2.Destroy;
Begin
  If DesktopPlayback Then NormalPlayback;

  If FDDXM <> Nil Then FDDXM.SetCallbackInterface(Nil, 0);
  OverlayCallback := Nil;
  FOverlayMixer := Nil;
  FFilterGraph := Nil;
  FVideoWindow := Nil;
  FVideoRenderer := Nil;
  FCaps.Free;
  FColorControl.Free;
  Inherited Destroy;
End;

Procedure TDSVideoWindowEx2.Resize;
Begin
  If (FVideoWindow <> Nil) And (Not FFullScreen) And (Not DesktopPlayback) Then
    If FIsVideoWindowOwner Then FVideoWindow.SetWindowPosition(0, 0, Width, Height)
    Else FVideoWindow.SetWindowPosition(Left, Top, Width, Height);
End;

Procedure TDSVideoWindowEx2.Loaded;
Begin
  Inherited Loaded;
  FWindowStyle := GetWindowLong(Handle, GWL_STYLE);
  FWindowStyleEx := GetWindowLong(Handle, GWL_EXSTYLE);
End;

Procedure TDSVideoWindowEx2.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  Inherited Notification(AComponent, Operation);
  If ((AComponent = FFilterGraph) And (Operation = OpRemove)) Then FFilterGraph := Nil;
End;

Procedure TDSVideoWindowEx2.SetFilterGraph(AFilterGraph: TFilterGraph);
Begin
  If AFilterGraph = FFilterGraph Then Exit;
  If FFilterGraph <> Nil Then Begin
    FFilterGraph.RemoveFilter(Self);
    FFilterGraph.RemoveEventNotifier(Self);
  End;
  If AFilterGraph <> Nil Then Begin
    AFilterGraph.InsertFilter(Self);
    AFilterGraph.InsertEventNotifier(Self);
  End;
  FFilterGraph := AFilterGraph;
End;

Procedure TDSVideoWindowEx2.SetTopMost(TopMost: Boolean);
Begin
  FTopMost := TopMost;
End;

Procedure TDSVideoWindowEx2.SetVideoZOrder;
Var
  Input: IPin;
  Enum: IEnumPins;
  ColorKey: TColorKey;
  DwColorKey: DWord;
  MPC: IMixerPinConfig;
Begin
  If Not GraphBuildOK Then Exit;
  Try
    ColorKey.KeyType := CK_INDEX Or CK_RGB;
    ColorKey.PaletteIndex := 0;
    ColorKey.LowColorValue := $000F000F;
    ColorKey.HighColorValue := $000F000F;

    FVideoWindowHandle := FindWindowEx(Parent.Handle, 0, 'VideoRenderer', Pchar(Name));
    If FVideoWindowHandle = 0 Then FVideoWindowHandle := FindWindowEx(0, 0, 'VideoRenderer', Pchar(Name));
    If FVideoWindowHandle = 0 Then Exit;
    SetWindowPos(FVideoWindowHandle, Handle, 0, 0, 0, 0, SWP_SHOWWINDOW Or SWP_NOSIZE Or SWP_NOMOVE Or SWP_NOCOPYBITS Or SWP_NOACTIVATE);
    If (FVideoWindowHandle <> 0) Then Begin
      FOverlayMixer.EnumPins(Enum);
      Enum.Next(1, Input, Nil);

      If Succeeded(Input.QueryInterface(IID_IMixerPinConfig2, MPC)) Then Begin
        MPC.GetColorKey(ColorKey, DwColorKey);
        FColorKey := ColorKey.HighColorValue;
        If Assigned(FOnColorKey) Then FOnColorKey(Self);
      End;
    End;
  Finally
    Input := Nil;
    Enum := Nil;
    MPC := Nil;
  End;
End;

Function TDSVideoWindowEx2.QueryInterface(Const IID: TGUID; Out Obj): HResult;
Begin
  Result := Inherited QueryInterface(IID, Obj);
  If Failed(Result) And Assigned(FBaseFilter) Then Result := FBaseFilter.QueryInterface(IID, Obj);
End;

Function TDSVideoWindowEx2.UpdateGraph: HResult;
Type
  TConnectAction = (CaConnect, CaDisConnect);

  PConnection = ^TConnection;

  TConnection = Record
    FromPin: IPin;
    ToPin: IPin;
    Action: TConnectAction;
  End;

Var
  FilterList: TFilterList;
  VMRPinList: TPinList;
  OVMPinList: TPinList;
  TmpPinList: TPinList;
  OrigConnections: TList;
  TmpVMRPinList: TPinList;
  Connection: PConnection;

  I, A: Integer;
  GUID: TGUID;
  PGB: IGraphBuilder;
  VRInputPin, VRConnectedToPin: IPin;
  OVMInputPin: IPin;
  OVMOutputPin: IPIN;
  Pin: IPin;
  PEnumPins: IEnumPins;
  Ul: Cardinal;
  Pd: TPinDirection;
  PinInfo: TPinInfo;
  Hr: HResult;
  VMR: IBaseFilter;
  Line21Dec, Line21Dec2: IBaseFilter;
  OVMInConected: Boolean;
  OVMOutConected: Boolean;
  Found: Boolean;
Label
  FailedSoReconnect, Cleanup, SetDrawExclMode;
Begin
  // Check if we are using Overlay.
  FOverlayMixer := Nil;
  FVideoRenderer := Nil;
  VMR := Nil;
  Line21Dec := Nil;
  Line21Dec2 := Nil;

  GraphWasUpdatet := True;
  OrigConnections := TList.Create;
  FilterList := TFilterList.Create(FilterGraph.FFilterGraph);
  If FilterList.Count > 0 Then
    For I := 0 To FilterList.Count - 1 Do Begin
      FilterList.Items[I].GetClassID(GUID);
      If ISEqualGUID(GUID, CLSID_OverlayMixer) Then FOverlayMixer := FilterList.Items[I];
      If ISEqualGUID(GUID, CLSID_VideoMixingRenderer) Then VMR := FilterList.Items[I];
      If ISEqualGUID(GUID, CLSID_VideoRenderer) Then FVideoRenderer := FilterList.Items[I];
    End;

  // The Graph holds no overlay mixer filter, Let's add one.
  Result := FFilterGraph.QueryInterface(IID_IGraphBuilder, PGB);
  If Failed(Result) Then Begin
    Goto Cleanup;
  End;

  If FOverlayMixer <> Nil Then Begin
    // Check if The Overlay Mixer that already exists is connected
    // correct to out VideoWindow
    OVMInConected := False;
    OVMOutConected := False;
    OVMPinList := TPinList.Create(FOverlayMixer);
    For I := 0 To OVMPinList.Count - 1 Do Begin
      OVMPinList.Items[I].QueryDirection(Pd);
      If Pd = PINDIR_OUTPUT Then Begin
        If Succeeded(OVMPinlist.Items[I].ConnectedTo(Pin)) Then Begin
          Pin.QueryPinInfo(PinInfo);
          If PinInfo.PFilter = FVideoRenderer Then OVMOutConected := True;
        End;
      End Else Begin
        If Succeeded(OVMPinlist.Items[I].ConnectedTo(Pin)) Then OVMInConected := True;
      End;
    End;
    If (Not OVMOutConected) Or (Not OVMInConected) Then Begin
      Result := E_FAIL;
      Goto Cleanup;
    End Else Begin
      // Everything looks okay stop here.
      OVMPinList.Free;
      Goto SetDrawExclMode;
    End;
  End;

  Result := CoCreateInstance(CLSID_OverlayMixer, Nil, CLSCTX_INPROC, IID_IBaseFilter, FOverlayMixer);
  If Failed(Result) Then Goto Cleanup;

  Result := PGB.AddFilter(FOverlayMixer, 'Overlay Mixer');
  If Failed(Result) Then Goto Cleanup;

  If FVideoRenderer = Nil Then Begin
    Result := E_Fail;
    Goto Cleanup;
  End;

  Result := FVideoRenderer.EnumPins(PEnumPins);
  If Failed(Result) Then Goto Cleanup;

  Result := PEnumPins.Next(1, VRInputPin, @Ul);
  If Failed(Result) Then Goto Cleanup;

  Result := VRInputPin.QueryDirection(Pd);
  If (Failed(Result)) Or (PD <> PINDIR_INPUT) Then Goto Cleanup;

  If VMR <> Nil Then Begin
    // The Graph Uses the new VideoMixerRenderer let's try to connect
    // all filter connected to the VideoMixerRenderer to the Overlay
    // Mixer filter instead.
    VMRPinList := TPinList.Create(VMR);
    OVMPinList := TPinList.Create(FOverlayMixer);
    TmpVMRPinList := TPinList.Create;

    I := 0;
    While (I < VMRPinList.Count) And (Succeeded(VMRPinList.Items[I].ConnectedTo(Pin))) Do Begin
      // Let's find the first Input Pin on the overlay mixer not
      // connected to anything.

      Result := Pin.Disconnect;
      If Failed(Result) Then Goto FailedSoReconnect;

      Result := VMRPinList.Items[I].Disconnect;
      If Failed(Result) Then Goto FailedSoReconnect;

      New(Connection);
      Connection^.FromPin := VMRPinList.Items[I];
      Connection^.ToPin := Pin;
      Connection^.Action := CaDisconnect;
      OrigConnections.Add(Connection);

      TmpVMRPinList.Add(Pin);
      VMRPinList.Update;
      Inc(I);
    End;

    I := 0;
    Repeat
      Pin := TmpVMRPinList[I];
      A := 0;
      Found := False;
      Repeat
        OVMPinList.Items[A].QueryDirection(Pd);
        If Pd = PINDIR_INPUT Then Begin
          OVMInputPin := OVMPinList.Items[A];
          If Failed(OVMPinList.Items[A].ConnectedTo(OVMOutputPin)) Then Begin
            Found := True;
          End;
        End;
        OVMPinList.Update;
        Inc(A);
      Until (A >= OVMPinList.Count) Or (Found);
      If Not Found Then Begin
        VMRPinList.Free;
        OVMPinList.Free;
        Result := E_Fail;
        Goto FailedSoReconnect;
      End;

      // Before connecting we need to check if the filter we ar working on is a Line21 Decoder2
      // And the exchange it with a Line21 Decoder because The Overlay Mixer Filter cannot connect
      // with a Line21 Decoder2
      Pin.QueryPinInfo(PinInfo);
      PinInfo.PFilter.GetClassID(GUID);

      If ISEqualGUID(GUID, CLSID_Line21Decoder2) Then Begin
        Line21Dec2 := PinInfo.PFilter;

        TmpPinList := TPinList.Create(Line21Dec2);
        Result := TmpPinList.Items[0].ConnectedTo(Pin);
        If Failed(Result) Then Goto FailedSoReconnect;

        Result := TmpPinList.Items[0].Disconnect;
        If Failed(Result) Then Goto FailedSoReconnect;

        Result := Pin.Disconnect;
        If Failed(Result) Then Goto FailedSoReconnect;

        New(Connection);
        Connection^.FromPin := Pin;
        Connection^.ToPin := TmpPinList.Items[0];
        Connection^.Action := CaDisconnect;
        OrigConnections.Add(Connection);
        TmpPinList.Free;

        Result := CoCreateInstance(CLSID_Line21Decoder, Nil, CLSCTX_INPROC, IID_IBaseFilter, Line21Dec);
        If Failed(Result) Then Goto Cleanup;

        Result := FilterGraph.FFilterGraph.AddFilter(Line21Dec, 'Line21 Decoder');
        If Failed(Result) Then Goto Cleanup;

        TmpPinList := TPinList.Create(Line21Dec);

        Result := FilterGraph.FFilterGraph.Connect(Pin, TmpPinList.Items[0]);
        If Failed(Result) Then Goto Cleanup;

        New(Connection);
        Connection^.FromPin := Pin;
        Connection^.ToPin := TmpPinList.Items[0];
        Connection^.Action := CaConnect;
        OrigConnections.Add(Connection);

        Pin := TmpPinList.Items[1];
        TmpPinList.Free;

        Result := PGB.Connect(Pin, OVMInputPin);
        If Failed(Result) Then Begin
          VMRPinList.Free;
          OVMPinList.Free;
          Goto Failedsoreconnect;
        End;

        New(Connection);
        Connection^.FromPin := Pin;
        Connection^.ToPin := OVMInputPin;
        Connection^.Action := CaConnect;
        OrigConnections.Add(Connection);
      End Else Begin
        Result := PGB.Connect(Pin, OVMInputPin);
        If Failed(Result) Then Begin
          VMRPinList.Free;
          OVMPinList.Free;
          Goto Failedsoreconnect;
        End;

        New(Connection);
        Connection^.FromPin := Pin;
        Connection^.ToPin := OVMInputPin;
        Connection^.Action := CaConnect;
        OrigConnections.Add(Connection);
      End;

      OVMPinList.Update;
      Inc(I);
    Until I >= TmpVMRPinList.Count;

    VMRPinList.Free;
    OVMPinList.Free;
    TmpVMRPinList.Free;
  End Else Begin
    Result := VRInputPin.ConnectedTo(VRConnectedToPin);
    If Failed(Result) Then Goto FailedSoReconnect;

    Result := VRInputPin.Disconnect;
    If Failed(Result) Then Goto FailedSoReconnect;

    Result := VRConnectedToPin.Disconnect;
    If Failed(Result) Then Goto FailedSoReconnect;

    New(Connection);
    Connection^.FromPin := VRInputPin;
    Connection^.ToPin := VRConnectedToPin;
    Connection^.Action := CaDisconnect;
    OrigConnections.Add(Connection);

    OVMPinList := TPinList.Create(FOverlayMixer);
    A := 0;
    Found := False;
    Repeat
      OVMPinList.Items[A].QueryDirection(Pd);
      If Pd = PINDIR_INPUT Then Begin
        OVMInputPin := OVMPinList.Items[A];
        If Failed(OVMPinList.Items[A].ConnectedTo(Pin)) Then Found := True;
      End;
      Inc(A);
    Until (A >= OVMPinList.Count) Or (Found);
    If Not Found Then Begin
      OVMPinList.Free;
      Result := E_Fail;
      Goto Cleanup;
    End;

    Result := PGB.Connect(VRConnectedToPin, OVMInputPin);
    If Failed(Result) Then Begin
      OVMPinList.Free;
      Goto FailedSoReconnect;
    End;

    New(Connection);
    Connection^.FromPin := VRConnectedToPin;
    Connection^.ToPin := OVMInputPin;
    Connection^.Action := CaConnect;
    OrigConnections.Add(Connection);

    OVMPinList.Free;
  End;

  Result := FOverlayMixer.FindPin('Output', OVMOutputPin);
  If Failed(Result) Then Goto FailedSoReconnect;

  Result := PGB.Connect(OVMOutputPin, VRInputPin);
  If Failed(Result) Then Goto FailedSoReconnect;

  New(Connection);
  Connection^.FromPin := OVMOutputPin;
  Connection^.ToPin := VRInputPin;
  Connection^.Action := CaConnect;
  OrigConnections.Add(Connection);

SetDrawExclMode:

  Result := FOverlayMixer.QueryInterface(IID_IDDrawExclModeVideo, FDDXM);
  If Failed(Result) Then Goto FailedSoReconnect;

  OverlayCallback := TOverlayCallback.Create(Self);

  Result := FDDXM.SetCallbackInterface(OverlayCallBack, 0);
  If Failed(Result) Then Goto FailedSoReconnect;

  If Line21Dec2 <> Nil Then Filtergraph.FFilterGraph.RemoveFilter(Line21Dec2);

  If VMR <> Nil Then Filtergraph.FFilterGraph.RemoveFilter(VMR);

  Goto Cleanup;

FailedSoReconnect:
  For I := OrigConnections.Count - 1 Downto 0 Do Begin
    Connection := OrigConnections[I];
    Case Connection^.Action Of
      CaConnect: Begin
          Connection^.FromPin.Disconnect;
          Connection^.ToPin.Disconnect;
        End;
      CaDisconnect: Begin
          PGB.Connect(Connection^.FromPin, Connection^.ToPin);
        End;
    End;
  End;

  If Line21Dec <> Nil Then FilterGraph.FFilterGraph.RemoveFilter(Line21Dec);

  Hr := PGB.RemoveFilter(FOverlayMixer);
  If Failed(Hr) Then Begin
    Result := Hr;
    Goto CleanUp;
  End;

  FOverlayMixer := Nil;

  If VMR <> Nil Then Begin
    PGB.RemoveFilter((FVideoWindow As IBaseFilter));
    FVideoWindow := Nil;
    FVideoRenderer := VMR;
    FVideoWindow := (VMR As IVIdeoWindow);
  End;

Cleanup:
  For I := 0 To OrigConnections.Count - 1 Do Begin
    Connection := OrigConnections[I];
    Connection^.FromPin := Nil;
    Connection^.ToPin := Nil;
  End;

  VMR := Nil;
  PEnumPins := Nil;
  OVMInputpin := Nil;
  OVMOutputPin := Nil;
  VRInputPin := Nil;
  VRConnectedToPin := Nil;
  Line21Dec := Nil;
  Line21Dec2 := Nil;
  OrigConnections.Free;
  FilterList.Free;
End;

Procedure TDSVideoWindowEx2.WndProc(Var Message: TMessage);
Begin
  If (CsDesigning In ComponentState) Then Begin
    Inherited WndProc(Message);
    Exit;
  End;

  If ((Message.Msg = WM_CONTEXTMENU) And FullScreen) Then Begin
    If Assigned(PopupMenu) Then
      If PopupMenu.AutoPopup Then Begin
        PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
        Message.Result := 1;
      End;

    Inherited WndProc(Message);
    Exit;
  End;

  If (Message.Msg = WM_ERASEBKGND) And (GraphBuildOk) Then Begin
    Message.Result := -1;
    Exit;
  End;

  If FNoScreenSaver Then
    If (Message.Msg = SC_SCREENSAVE) Or (Message.Msg = SC_MONITORPOWER) Then Begin
      Message.Result := 0;
      Exit;
    End;

  Inherited WndProc(Message);
End;

Procedure TDSVideoWindowEx2.ClearBack;
Var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  BackBrush, OverlayBrush: HBrush;
Begin
  BackBrush := 0;
  OverlayBrush := 0;
  If (CsDestroying In Componentstate) Then Exit;
  DC := GetDC(0);
  MemBitmap := CreateCompatibleBitmap(DC, ClientRect.Right, ClientRect.Bottom);
  ReleaseDC(0, DC);
  MemDC := CreateCompatibleDC(0);
  OldBitmap := SelectObject(MemDC, MemBitmap);
  Try
    DC := GetDC(Handle);
    BackBrush := CreateSolidBrush(Color);
    FillRect(MemDC, Rect(0, 0, ClientRect.Right, ClientRect.Bottom), BackBrush);
    If Not(CsDesigning In ComponentState) Then Begin
      If Succeeded(GetVideoInfo) And (FOverlayVisible) Then Begin
        OverlayBrush := CreateSolidBrush(FColorKey);
        FillRect(MemDC, FVideoRect, OverlayBrush);
      End;
    End;
    BitBlt(DC, 0, 0, Self.ClientRect.Right, Self.ClientRect.Bottom, MemDC, 0, 0, SRCCOPY);
  Finally
    SelectObject(MemDC, OldBitmap);
    DeleteDC(MemDC);
    DeleteObject(MemBitmap);
    DeleteObject(BackBrush);
    DeleteObject(OverlayBrush);
    ReleaseDC(Handle, DC);
  End;
  If Assigned(FOnPaint) Then FOnPaint(Self);
End;

Procedure TDSVideoWindowEx2.Paint;
Begin
  Inherited Paint;
  Clearback;
End;

Function TDSVideoWindowEx2.GetVideoInfo: HResult;
Var
  BasicVideo: IBasicVideo2;
  AspX, AspY: DWord;
  VideoWidth, VideoHeight: DWord;
Begin
  Result := E_Fail;
  If (FVideoWindow = Nil) Or (FBaseFilter = Nil) Or (FDDXM = Nil) Or (FVideoRenderer = Nil) Or (FOverlayMixer = Nil) Then Exit;

  Try
    If FAspectMode = RmLetterbox Then Begin
      FDDXM.GetNativeVideoProps(VideoWidth, VideoHeight, AspX, AspY);
      FVideoRect := StretchRect(ClientRect, Rect(0, 0, AspX, AspY));
    End
    Else FVideoRect := ClientRect;
    Result := S_OK;
  Finally
    BasicVideo := Nil;
  End;
End;

Procedure TDSVideoWindowEx2.StartDesktopPlayback;
Type
  TMonitorDefaultTo = (MdNearest, MdNull, MdPrimary);
Const
  MonitorDefaultFlags: Array [TMonitorDefaultTo] Of DWORD = (MONITOR_DEFAULTTONEAREST, MONITOR_DEFAULTTONULL, MONITOR_DEFAULTTOPRIMARY);
  Function FindMonitor(Handle: HMONITOR): TMonitor;
  Var
    I: Integer;
  Begin
    Result := Nil;
    For I := 0 To Screen.MonitorCount - 1 Do
      If HMonitor(Screen.Monitors[I].Handle) = HMonitor(Handle) Then Begin
        Result := Screen.Monitors[I];
        Break;
      End;
  End;

  Function MonitorFromWindow(Const Handle: THandle; MonitorDefault: TMonitorDefaultTo = MdNearest): TMonitor;
  Begin
    Result := FindMonitor(MultiMon.MonitorFromWindow(Handle, MonitorDefaultFlags[MonitorDefault]));
  End;

Begin
  StartDesktopPlayback(MonitorfromWindow(Self.Handle));
End;

Procedure TDSVideoWindowEx2.StartDesktopPlayBack(OnMonitor: TMonitor);

  Procedure SetWallpaper(SWallpaperBMPPath: String);
  Var
    Reg: TRegistry;
  Begin
    Reg := TRegistry.Create;
    With Reg Do Begin
      RootKey := HKEY_CURRENT_USER;
      If KeyExists('\Control Panel\Desktop') Then
        If OpenKey('\Control Panel\Desktop', False) Then Begin
          If ValueExists('WallPaper') Then WriteString('WallPaper', SWallpaperBMPPath);
        End;
    End;
    Reg.Free;
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, Nil, SPIF_SENDWININICHANGE);
  End;

  Function GetWallpaper: String;
  Var
    Reg: TRegistry;
  Begin
    Result := '';
    Reg := TRegistry.Create;
    With Reg Do Begin
      RootKey := HKEY_CURRENT_USER;
      If KeyExists('\Control Panel\Desktop') Then
        If OpenKey('\Control Panel\Desktop', False) Then Begin
          If ValueExists('WallPaper') Then Result := ReadString('Wallpaper');
        End;
    End;
    Reg.Free;
  End;

Var
  ColorIndex: Integer;
  Color: Longint;
Begin
  If DesktopPlayback Then Exit;

  FMonitor := OnMonitor;
  OldDesktopPic := GetWallpaper;
  ColorIndex := COLOR_DESKTOP;
  OldDesktopColor := GetSysColor(ColorIndex);

  SetWallPaper('');
  Color := ColorTorgb(FColorKey);
  SetSysColors(1, ColorIndex, Color);

  If FullScreen Then NormalPlayback;

  FOldParent := Parent;

  Parent := FFullScreenControl;

  FFullScreenControl.BoundsRect := Rect(OnMonitor.Left, OnMonitor.Top, OnMonitor.Left + OnMonitor.Width, OnMonitor.Top + OnMonitor.Height);

  FFullScreenControl.Show;

  FDesktopPlay := True;

  RefreshVideoWindow;
  If GraphBuildOk Then SetVideoZOrder;

  FFullScreenControl.Hide;
  FOverlayVisible := False;
  ClearBack;
  If Assigned(FOnOverlay) Then FOnOverlay(Self, False);
End;

Procedure TDSVideoWindowEx2.NormalPlayback;

  Procedure SetWallpaper(SWallpaperBMPPath: String);
  Var
    Reg: TRegistry;
  Begin
    Reg := TRegistry.Create;
    With Reg Do Begin
      RootKey := HKEY_CURRENT_USER;
      If KeyExists('\Control Panel\Desktop') Then
        If OpenKey('\Control Panel\Desktop', False) Then Begin
          If ValueExists('WallPaper') Then WriteString('WallPaper', SWallpaperBMPPath);
        End;
    End;
    Reg.Free;
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, Nil, SPIF_SENDWININICHANGE);
  End;

Var
  ColorIndex: Integer;
Begin
  If DesktopPlayback Then Begin
    ColorIndex := COLOR_DESKTOP;

    SetWallPaper(OldDesktopPic);
    SetSysColors(1, ColorIndex, OldDesktopColor);

    FDesktopPlay := False;
    If (CsDestroying In Componentstate) Then Exit;
  End;

  If FoldParent <> Nil Then Parent := FOldParent;

  If FullScreen Then Begin
    FFullScreenControl.Hide;
    FFullScreenControl.Invalidate;
    FFullScreen := False;
  End;
  RefreshVideoWindow;
  If GraphBuildOk Then SetVideoZOrder;
  FOverlayVisible := True;
  ClearBack;
  If Assigned(FOnOverlay) Then FOnOverlay(Self, True);
  FMonitor := Nil;
End;

Procedure TDSVideoWindowEx2.StartFullScreen;
Type
  TMonitorDefaultTo = (MdNearest, MdNull, MdPrimary);
Const
  MonitorDefaultFlags: Array [TMonitorDefaultTo] Of DWORD = (MONITOR_DEFAULTTONEAREST, MONITOR_DEFAULTTONULL, MONITOR_DEFAULTTOPRIMARY);
  Function FindMonitor(Handle: HMONITOR): TMonitor;
  Var
    I: Integer;
  Begin
    Result := Nil;
    For I := 0 To Screen.MonitorCount - 1 Do
      If HMonitor(Screen.Monitors[I].Handle) = HMonitor(Handle) Then Begin
        Result := Screen.Monitors[I];
        Break;
      End;
  End;

  Function MonitorFromWindow(Const Handle: THandle; MonitorDefault: TMonitorDefaultTo = MdNearest): TMonitor;
  Begin
    Result := FindMonitor(MultiMon.MonitorFromWindow(Handle, MonitorDefaultFlags[MonitorDefault]));
  End;

Begin
  StartFullScreen(MonitorfromWindow(Self.Handle));
End;

Procedure TDSVideoWindowEx2.StartFullScreen(OnMonitor: TMonitor);
Begin
  If FFullscreen Then Exit;

  If DesktopPlayback Then NormalPlayback;

  FMonitor := OnMonitor;
  FOldParent := Parent;

  Parent := FFullScreenControl;

  FFullScreenControl.BoundsRect := Rect(OnMonitor.Left, OnMonitor.Top, OnMonitor.Left + OnMonitor.Width, OnMonitor.Top + OnMonitor.Height);

  If FTopMost Then FFullScreenControl.FormStyle := FsStayOnTop
  Else FFullScreenControl.FormStyle := FsNormal;

  FFullScreenControl.Show;

  FFullScreen := True;

  RefreshVideoWindow;
  If GraphBuildOk Then SetVideoZOrder;
End;

Procedure TDSVideoWindowEx2.FullScreenCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  If CsDestroying In Componentstate Then Begin
    NormalPlayback;
    CanClose := True;
  End
  Else CanClose := False;
End;

Procedure TDSVideoWindowEx2.SetZoom(Value: Integer);
Var
  Ratio: Real;
  TmpX, TmpY: Real;
  TmpLeft, TmpTop: Real;
  BasicVideo2: IBasicVideo2;
  SLeft, STop, SWidth, SHeight: Integer;
Begin
  // Set DigitalZoom
  If (Value < 0) Or (Value > 99) Then Begin
    Raise Exception.CreateFmt('Value %d out of range. Value must bee between 0 -> 99', [Value]);
    Exit;
  End;

  If (CsDesigning In ComponentState) Or (FVideoRenderer = Nil) Then Begin
    FZoom := Value;
    Exit;
  End;

  BasicVideo2 := Nil;
  Try
    If (FVideoRenderer.QueryInterface(IID_IBasicVideo2, BasicVideo2) = S_OK) Then Begin
      BasicVideo2.SetDefaultSourcePosition;
      BasicVideo2.Get_SourceLeft(SLeft);
      BasicVideo2.Get_SourceTop(STop);
      BasicVideo2.Get_SourceWidth(SWidth);
      BasicVideo2.Get_SourceHeight(SHeight);

      Ratio := SHeight / SWidth;

      TmpX := SWidth - ((Value * Swidth) / 100);
      TmpY := TmpX * Ratio;

      TmpLeft := (SWidth - TmpX) / 2;
      TmpTop := (SHeight - TmpY) / 2;

      BasicVideo2.Put_SourceWidth(Trunc(TmpX));
      BasicVideo2.Put_SourceHeight(Trunc(TmpY));
      BasicVideo2.Put_SourceLeft(Trunc(TmpLeft));
      BasicVideo2.Put_SourceTop(Trunc(TmpTop));
    End;
    FZoom := Value;
  Finally
    BasicVideo2 := Nil;
  End;
End;

Procedure TDSVideoWindowEx2.SetAspectMode(Value: TRatioModes);
Var
  Input: IPin;
  Enum: IEnumPins;
  PMPC: IMixerPinConfig2;
Begin
  If (CsDesigning In ComponentState) Or (FVideoRenderer = Nil) Or (FOverlayMixer = Nil) Then Begin
    FAspectMode := Value;
    Exit;
  End;

  Try
    FOverlayMixer.EnumPins(Enum);
    Enum.Next(1, Input, Nil);

    If Succeeded(Input.QueryInterface(IID_IMixerPinConfig2, PMPC)) Then
      If Succeeded(PMPC.SetAspectRatioMode(TAMAspectRatioMode(Integer(Value)))) Then FAspectMode := Value;
  Finally
    Input := Nil;
    Enum := Nil;
    PMPC := Nil;
  End;
  If (GraphBuildOk) And (Not FDesktopPlay) Then Clearback;
End;

Procedure TDSVideoWindowEx2.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  MPos: TPoint;
Begin
  If Ffullscreen Then MPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else MPos := Point(X, Y);

  If FVideoWindow <> Nil Then Begin
    If GraphBuildOK Then Begin
      If Self.Cursor = Crnone Then Begin
        Self.Cursor := RememberCursor;
        LMousePos.X := MPos.X;
        LMousePos.Y := MPos.Y;
        LCursorMov := GetTickCount;
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
      End;
    End Else Begin
      FVideoWindow.IsCursorHidden(IsHidden);
      If IsHidden Then Begin
        FVideoWindow.HideCursor(False);
        LMousePos.X := MPos.X;
        LMousePos.Y := MPos.Y;
        LCursorMov := GetTickCount;
        IsHidden := False;
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
      End;
    End;
  End;

  Inherited MouseDown(Button, Shift, MPos.X, MPos.Y);
End;

Procedure TDSVideoWindowEx2.MouseMove(Shift: TShiftState; X, Y: Integer);
Var
  MPos: TPoint;
Begin
  If Ffullscreen Then MPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else MPos := Point(X, Y);

  If (LMousePos.X <> MPos.X) Or (LMousePos.Y <> MPos.Y) Then Begin
    LMousePos.X := MPos.X;
    LMousePos.Y := MPos.Y;
    LCursorMov := GetTickCount;
    If FVideoWindow <> Nil Then Begin
      If GraphBuildOk Then Begin
        If Self.Cursor = Crnone Then Begin
          Self.Cursor := RememberCursor;
          If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
        End;
      End Else Begin
        FVideoWindow.IsCursorHidden(IsHidden);
        If IsHidden Then Begin
          FVideoWindow.HideCursor(False);
          IsHidden := False;
          If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
        End;
      End;
    End;
  End;

  Inherited MouseMove(Shift, MPos.X, MPos.Y);
End;

Procedure TDSVideoWindowEx2.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
  MPos: TPoint;
Begin
  If Ffullscreen Then MPos := Point(Mouse.CursorPos.X, Mouse.CursorPos.Y)
  Else MPos := Point(X, Y);

  If FVideoWindow <> Nil Then Begin
    If GraphBuildOK Then Begin
      If Self.Cursor = Crnone Then Begin
        Self.Cursor := RememberCursor;
        LMousePos.X := MPos.X;
        LMousePos.Y := MPos.Y;
        LCursorMov := GetTickCount;
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
      End;
    End Else Begin
      FVideoWindow.IsCursorHidden(IsHidden);
      If IsHidden Then Begin
        FVideoWindow.HideCursor(False);
        LMousePos.X := MPos.X;
        LMousePos.Y := MPos.Y;
        LCursorMov := GetTickCount;
        IsHidden := False;
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, True);
      End;
    End;
  End;
  Inherited MouseUp(Button, Shift, MPos.X, MPos.Y);
End;

Procedure TDSVideoWindowEx2.MyIdleHandler(Sender: TObject; Var Done: Boolean);
Var
  Pt: TPoint;
Begin
  Done := True;
  If (FIdleCursor = 0) Or (CsDesigning In ComponentState) Then Exit;
  If (GetTickCount - LCursorMov >= Cardinal(FIdleCursor)) And (FVideoWindow <> Nil) Then Begin
    If GraphBuildOK Then Begin
      If Self.Cursor <> CrNone Then Begin
        RememberCursor := Self.Cursor;
        Self.Cursor := CrNone;
        GetCursorPos(Pt);
        SetCursorPos(Pt.X, Pt.Y);
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, False);
      End;
    End Else Begin
      FVideoWindow.IsCursorHidden(IsHidden);
      If Not IsHidden Then Begin
        FVideoWindow.HideCursor(True);
        IsHidden := True;
        GetCursorPos(Pt);
        SetCursorPos(Pt.X, Pt.Y);
        If Assigned(FOnCursorVisible) Then FOnCursorVisible(Self, False);
      End;
    End;
  End;
End;

{ TVMRBitmap }

Constructor TVMRBitmap.Create(VideoWindow: TVideoWindow);
Begin
  Assert(Assigned(VideoWindow), 'No valid video Window.');
  FCanvas := TCanvas.Create;
  FVideoWindow := VideoWindow;
  FillChar(FVMRALPHABITMAP, SizeOf(FVMRALPHABITMAP), 0);
  Options := [];
  FVMRALPHABITMAP.Hdc := 0;
  FVMRALPHABITMAP.FAlpha := 1;
End;

Destructor TVMRBitmap.Destroy;
Begin
  ResetBitmap;
  FCanvas.Free;
End;

Procedure TVMRBitmap.Draw;
Var
  VMRMixerBitmap: IVMRMixerBitmap9;
Begin
  If Succeeded(FVideoWindow.QueryInterface(IVMRMixerBitmap9, VMRMixerBitmap)) Then VMRMixerBitmap.SetAlphaBitmap(@FVMRALPHABITMAP);
End;

Procedure TVMRBitmap.DrawTo(Left, Top, Right, Bottom, Alpha: Single; DoUpdate: Boolean = False);
Begin
  With FVMRALPHABITMAP Do Begin
    RDest.Left := Left;
    RDest.Top := Top;
    RDest.Right := Right;
    RDest.Bottom := Bottom;
    FAlpha := Alpha;
  End;
  If DoUpdate Then Update
  Else Draw;
End;

Function TVMRBitmap.GetAlpha: Single;
Begin
  Result := FVMRALPHABITMAP.FAlpha;
End;

Function TVMRBitmap.GetColorKey: COLORREF;
Begin
  Result := FVMRALPHABITMAP.ClrSrcKey;
End;

Function TVMRBitmap.GetDest: TVMR9NormalizedRect;
Begin
  Result := FVMRALPHABITMAP.RDest;
End;

Function TVMRBitmap.GetDestBottom: Single;
Begin
  Result := FVMRALPHABITMAP.RDest.Bottom;
End;

Function TVMRBitmap.GetDestLeft: Single;
Begin
  Result := FVMRALPHABITMAP.RDest.Left;
End;

Function TVMRBitmap.GetDestRight: Single;
Begin
  Result := FVMRALPHABITMAP.RDest.Right
End;

Function TVMRBitmap.GetDestTop: Single;
Begin
  Result := FVMRALPHABITMAP.RDest.Top;
End;

Function TVMRBitmap.GetSource: TRect;
Begin
  Result := FVMRALPHABITMAP.RSrc;
End;

Procedure TVMRBitmap.LoadBitmap(Bitmap: TBitmap);
Var
  TmpHDC, HdcBMP: HDC;
  BMP: Windows.TBITMAP;
Begin
  Assert(Assigned(Bitmap), 'Invalid Bitmap.');
  ResetBitmap;
  TmpHDC := GetDC(FVideoWindow.Handle);
  If (TmpHDC = 0) Then Exit;
  HdcBMP := CreateCompatibleDC(TmpHDC);
  ReleaseDC(FVideoWindow.Handle, TmpHDC);
  If (HdcBMP = 0) Then Exit;
  If (0 = GetObject(Bitmap.Handle, Sizeof(BMP), @BMP)) Then Exit;
  FBMPOld := SelectObject(HdcBMP, Bitmap.Handle);
  If (FBMPOld = 0) Then Exit;
  FVMRALPHABITMAP.Hdc := HdcBMP;
  FCanvas.Handle := HdcBMP;
End;

Procedure TVMRBitmap.LoadEmptyBitmap(Width, Height: Integer; PixelFormat: TPixelFormat; Color: TColor);
Var
  Bitmap: TBitmap;
Begin
  Bitmap := TBitmap.Create;
  Try
    Bitmap.Width := Width;
    Bitmap.Height := Height;
    Bitmap.PixelFormat := PixelFormat;
    Bitmap.Canvas.Brush.Color := Color;
    Bitmap.Canvas.FillRect(Bitmap.Canvas.ClipRect);
    LoadBitmap(Bitmap);
  Finally
    Bitmap.Free;
  End;
End;

Procedure TVMRBitmap.ResetBitmap;
Begin
  FCanvas.Handle := 0;
  If FVMRALPHABITMAP.Hdc <> 0 Then Begin
    DeleteObject(SelectObject(FVMRALPHABITMAP.Hdc, FBMPOld));
    DeleteDC(FVMRALPHABITMAP.Hdc);
    FVMRALPHABITMAP.Hdc := 0;
  End;
End;

Procedure TVMRBitmap.SetAlpha(Const Value: Single);
Begin
  FVMRALPHABITMAP.FAlpha := Value;
End;

Procedure TVMRBitmap.SetColorKey(Const Value: COLORREF);
Begin
  FVMRALPHABITMAP.ClrSrcKey := Value;
End;

Procedure TVMRBitmap.SetDest(Const Value: TVMR9NormalizedRect);
Begin
  FVMRALPHABITMAP.RDest := Value;
End;

Procedure TVMRBitmap.SetDestBottom(Const Value: Single);
Begin
  FVMRALPHABITMAP.RDest.Bottom := Value;
End;

Procedure TVMRBitmap.SetDestLeft(Const Value: Single);
Begin
  FVMRALPHABITMAP.RDest.Left := Value;
End;

Procedure TVMRBitmap.SetDestRight(Const Value: Single);
Begin
  FVMRALPHABITMAP.RDest.Right := Value;
End;

Procedure TVMRBitmap.SetDestTop(Const Value: Single);
Begin
  FVMRALPHABITMAP.RDest.Top := Value;
End;

Procedure TVMRBitmap.SetOptions(Options: TVMRBitmapOptions);
Begin
  FOptions := Options;
  FVMRALPHABITMAP.DwFlags := VMR9AlphaBitmap_hDC;
  If VmrbDisable In Options Then FVMRALPHABITMAP.DwFlags := FVMRALPHABITMAP.DwFlags Or VMR9AlphaBitmap_Disable;
  If VmrbSrcColorKey In Options Then FVMRALPHABITMAP.DwFlags := FVMRALPHABITMAP.DwFlags Or VMR9AlphaBitmap_SrcColorKey;
  If VmrbSrcRect In Options Then FVMRALPHABITMAP.DwFlags := FVMRALPHABITMAP.DwFlags Or VMR9AlphaBitmap_SrcRect;
End;

Procedure TVMRBitmap.SetSource(Const Value: TRect);
Begin
  FVMRALPHABITMAP.RSrc := Value;
End;

Procedure TVMRBitmap.Update;
Var
  VMRMixerBitmap: IVMRMixerBitmap9;
Begin
  If Succeeded(FVideoWindow.QueryInterface(IVMRMixerBitmap9, VMRMixerBitmap)) Then VMRMixerBitmap.UpdateAlphaBitmapParameters(@FVMRALPHABITMAP);
End;

End.
