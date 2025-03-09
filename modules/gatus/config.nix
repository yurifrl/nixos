{
  web = { port = 8080; };
  endpoints = [
    {
      name = "Example";
      group = "Default";
      url = "https://example.org";
      interval = "30s";
      conditions = [ "[STATUS] == 200" "[RESPONSE_TIME] < 500" ];
    }
    {
      name = "Google";
      group = "Default";
      url = "https://google.com";
      interval = "30s";
      conditions = [ "[STATUS] == 200" "[RESPONSE_TIME] < 1000" ];
    }
  ];
} 