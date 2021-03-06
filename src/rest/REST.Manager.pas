﻿// Eduardo - 07/12/2020
unit REST.Manager;

interface

uses
  FireDAC.Comp.Client,
  REST.Connection,
  REST.Table,
  REST.Query;

type
  TRESTManager = class
  private
    FURL: String;
    FConnection: TRESTConnection;
    FTable: TRESTTable;
    FQuery: TRESTQuery;
  public
    constructor Create(URL: String; ATable: TFDMemTable);
    destructor Destroy; override;
    property Connection: TRESTConnection read FConnection;
    property Table: TRESTTable read FTable;
    property Query: TRESTQuery read FQuery;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Net.HttpClient;

{ TRESTManager }

constructor TRESTManager.Create(URL: String; ATable: TFDMemTable);
begin
  FURL := URL;
  FConnection := TRESTConnection.Create;
  FTable := TRESTTable.Create(ATable);
  FQuery := TRESTQuery.Create;

  FTable.RESTGet(
    function: TJSONArray
    var
      vJSON: TJSONValue;
    begin
      vJSON := FConnection.Execute(sHTTPMethodGet, FURL + FQuery.Text);
      try
        Result := TJSONArray(vJSON.GetValue<TJSONArray>('sql').Clone);
      finally
        FreeAndNil(vJSON);
      end;
    end
  );

  FTable.RESTPut(
    procedure(Data: TJSONArray)
    begin
      FConnection.Execute(sHTTPMethodPut, FURL, Data).Free;
    end
  );

  FTable.RESTPost(
    procedure(Data: TJSONArray)
    begin
      FConnection.Execute(sHTTPMethodPost, FURL, Data).Free;
    end
  );

  FTable.RESTDelete(
    procedure(Data: TJSONArray)
    var
      vItem: TJSONValue;
      oResult: TJSONObject;
    begin
      for vItem in Data do
      begin
        if Assigned(vItem.FindValue('id')) then
        begin
          oResult := TJSONObject(FConnection.Execute(sHTTPMethodDelete, FURL +'/'+ vItem.GetValue<String>('id')));
          try
            if Assigned(oResult) and Assigned(oResult.FindValue('sucesso')) and not oResult.GetValue<Boolean>('sucesso') then
            begin
              if Assigned(oResult.FindValue('mensagem')) then
                raise Exception.Create(oResult.GetValue<String>('mensagem'))
              else
                raise Exception.Create(oResult.ToJSON);
            end;
          finally
            if Assigned(oResult) then
              FreeAndNil(oResult);
          end;
        end;
      end;
    end
  );
end;

destructor TRESTManager.Destroy;
begin
  FreeAndNil(FQuery);
  FreeAndNil(FTable);
  FreeAndNil(FConnection);
  inherited;
end;

end.
