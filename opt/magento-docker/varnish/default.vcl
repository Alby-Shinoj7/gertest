vcl 4.1;

backend default {
    .host = "nginx-backend";
    .port = "8080";
}

sub vcl_recv {
    return (pass);
}
