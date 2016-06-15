CREATE procedure validareTertiMFin              
-- exec validareTertiMFin     
as               
begin try                
                
--verific tabela                
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[validareTerti]') AND type in (N'U'))                
 BEGIN                
  CREATE TABLE [dbo].[validareTerti](                
   [Cod_fiscal] [varchar](20) NOT NULL,                
   [Denumire] [varchar](100) NOT NULL,                
   [Localitate] [varchar](50) NOT NULL,                
   [Judet] [varchar](50) NOT NULL,                
   [Adresa] [varchar](100) NOT NULL,                
   [Telefon_fax] [varchar](20) NOT NULL,                
   [Nr_ord_reg] [varchar](60) NOT NULL,                
   [TVA] [varchar](10) NOT NULL                
  ) ON [PRIMARY]                
 END                
  ELSE                
 BEGIN                
  TRUNCATE TABLE [validareTerti]                
 END                
 
declare @tert varchar(30), @fetch_tert int, @xmlOut varchar(max), @RequestText as varchar(max)                
declare crstert cursor for                
select distinct ltrim(rtrim(replace(replace(replace(rtrim(cod_fiscal),'R',''),'O',''),'-',''))) from terti t                 
 inner join infotert i  on t.tert = i.tert and t.subunitate = i.subunitate                 
            and i.identificator = '' and zile_inc = '0'                
 where cod_fiscal not in ('','-') and len(cod_fiscal)<11 and len(replace(cod_fiscal,'.',''))>0                
 --and ltrim(rtrim(replace(replace(rtrim(cod_fiscal),'R',''),'O',''))) = 'KS 022054'                
 --and t.judet = 'CJ'                
  order by 1                
open crstert                
fetch next from crstert into @tert                
set @fetch_tert=@@FETCH_STATUS  
            
while @fetch_tert=0                
begin                
	-- apelare webService                 
	set @RequestText=                
	'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">                
	  <soap:Body>                
		<iaDateFirma xmlns="http://tempuri.org/">                
		  <CUI>'+@tert+'</CUI>                
		</iaDateFirma>                
	  </soap:Body>                
	</soap:Envelope>'   
	/*apelarea procedurii*/                
	exec spHTTPRequest                
	'http://mfinante.asis.ro/mfinante.asmx',                
	'POST', -- tipul metodei POST or GET                
	@RequestText, --corpul xml care se trimite la webservice                 
	'http://tempuri.org/iaDateFirma', -- apelare operatie iaDateFirma din cadrul webService-ului                 
	'', --username                 
	'', --password                
	@xmlOut out -- raspunsul de la webService                
	----          
	 --tratez diacritice                
	 set @xmlOut = dbo.CaractereSpeciale(@xmlOut)        

	declare @lOk int  
	set @lOk=1  
	begin try                 
	 declare @xmlTert xml                
	 set @xmlTert=(select convert(xml,@xmlOut).query('//Firma'))                
	end try  
	begin catch  
	 set @lOk=0  
	end catch  
	  
	if @lOk=1  
	begin  
	 declare @tertMfinante varchar(30), @dentert varchar(100), @localitate varchar(100), @Judet varchar(50), @adresa  varchar(100), @Telfax varchar(50), @nrordreg varchar(50), @tva varchar(10)                
	                 
	 select @tertMfinante = @xmlTert.value('(/Firma/@codfiscal)[1]','varchar(30)'),                
	  @dentert = @xmlTert.value('(/Firma/@dentert)[1]','varchar(100)'),                
	   @Telfax = @xmlTert.value('(/Firma/@telefon_fax)[1]','varchar(50)'),                
	   @nrordreg = @xmlTert.value('(/Firma/@nrordreg)[1]','varchar(50)'),                
	   @tva = @xmlTert.value('(/Firma/@tva)[1]','varchar(10)'),                
	   @localitate = @xmlTert.value('(/Firma/@localitate)[1]','varchar(100)'),               
	   @Judet = @xmlTert.value('(/Firma/@judet)[1]','varchar(50)'),                
	   @adresa = @xmlTert.value('(/Firma/@adresa)[1]','varchar(100)')                
	                   
	 --se verifica TVA. Codul fiscal daca nu exista nu se insereaza pozitie            
	 if @tva is not null                 
	 if exists (select 1 from validareTerti where cod_fiscal=@tertMfinante)                 
	  update validareTerti set Denumire=@dentert, Localitate=@localitate, Judet=@Judet, Nr_ord_reg=@nrordreg,       Telefon_fax=@telfax                
	   where Cod_fiscal=@tertMfinante                
	  else                
	  begin                 
	  select @tva=(case when @tva in ('true','1') then 1 else 0 end)                
	  insert into validareTerti (Cod_fiscal,Denumire,Localitate,Judet,Adresa,Telefon_fax,Nr_ord_reg,TVA)                
	   values  (@tertMfinante, @dentert, @localitate, @Judet, @adresa, @Telfax, @nrordreg, @tva)                
	end  
	 end                
	 fetch next from crstert into @tert                
	 set @fetch_tert=@@FETCH_STATUS                
 end                
                 
 close crstert                
deallocate crstert                
                
end try              
               
begin catch                
 declare @mesajeroare varchar(max)                
 set @mesajeroare = @tert + '' + ERROR_MESSAGE()                
                 
 if (@mesajEroare<>'')                
 begin                
  exec msdb..sp_send_dbmail @Profile_name='Server asis', @recipients='ghita@asw.ro',                    
   @Subject='Eroare procedura validare terti',                    
   @body= @mesajEroare                
 end                
                 
end catch   
  