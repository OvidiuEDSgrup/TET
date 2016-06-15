--***
CREATE procedure wStergFormular                       
--declare      
@sesiune varchar(50),@tip varchar(2),@numar varchar(20)  
as

set nocount on                      
declare @cHostid char(10),@cDirector varchar(1000),@cFisier varchar(100),@utilizator varchar(255) ,@cTextSelect varchar(2000)  
--select @utilizator=id from utilizatori where observatii=suser_name()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
IF @utilizator IS NULL
	RETURN -1

set @cHostid=rtrim(ltrim(str(host_id())))                      
set @cDirector='d:\newsite\asisria\formulare\'      
set @cFisier=@cDirector+@tip+@numar+'.doc'      
set @cTextSelect='exec xp_cmdshell '+''''+'del '+@cFisier+''''        
exec (@cTextSelect)
