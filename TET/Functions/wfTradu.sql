--***
create function wfTradu (@limba varchar(50),@textorig varchar(500))
returns varchar(500)
as begin
return isnull((select texttradus from webtraduceri 
where limba=@limba and Textoriginal=@textorig),@textorig)
end
