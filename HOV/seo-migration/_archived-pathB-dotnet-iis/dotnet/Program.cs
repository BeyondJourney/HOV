using HouseOfVacation.Seo;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();
builder.Services.AddSeoRedirects(builder.Configuration);
builder.Services.AddNotFoundFallback(builder.Configuration);

// Shared hosting almost always puts a proxy in front. Without this the app
// sees http:// at origin and the HTTPS rule loops forever.
builder.Services.Configure<ForwardedHeadersOptions>(o =>
{
    o.ForwardedHeaders = ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedFor;
    o.KnownNetworks.Clear();
    o.KnownProxies.Clear();
});

// File logging - shared hosts rarely give you a log viewer.
builder.Logging.AddSimpleConsole(o => { o.SingleLine = true; o.TimestampFormat = "yyyy-MM-dd HH:mm:ss "; });

var app = builder.Build();

app.UseForwardedHeaders();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/error/");
    app.UseHsts();
}

// ---------------------------------------------------------------------------
// ORDER IS CRITICAL.
//
//   UseNotFoundFallback  is registered FIRST because it inspects the response
//                        on the way back OUT of the pipeline.
//   UseSeoRedirects      must run BEFORE static files, so that a mis-cased or
//                        slash-less URL is corrected before anything is served.
// ---------------------------------------------------------------------------
app.UseNotFoundFallback();
app.UseSeoRedirects();

app.UseStaticFiles();   // serves /wp-content/uploads/ from wwwroot, unchanged
app.UseRouting();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
