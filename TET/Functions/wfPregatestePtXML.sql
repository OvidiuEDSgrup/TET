--***
create function [dbo].[wfPregatestePtXML](@string varchar(max))
returns varchar(max)
as 
begin
return replace(replace(replace(replace(replace(@string, '&', '&amp;' ), '<', '&lt;' ), '>', '&gt;' ), '"', '&quot;' ), '''', '&#39;' )
end
/*
& - &amp;
< - &lt;
> - &gt;
" - &quot;
' - &#39;
*/
