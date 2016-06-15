--***
create procedure validareStocNegativ @Subunitate varchar(9),@Tip_gestiune varchar(1),@Cod_gestiune varchar(20),@Cod varchar(20),
	@Cod_intrare varchar(13),@Cantitate float, @Tip varchar(2),@Numar varchar(20),@Data datetime,@Numar_pozitie int=0,@tipm char(1)=''
as
begin
	declare @faraStoc int,	--bifa veche din asisplus de stoc negativ
		@faraValidStoc int,	--bifa prin care se poate exclude validarea stoc negativ in triggerele de stocuri(docstoc...etc)->pt cei cu replicari	
		@iesiriStocLaData int,	-- validare stocuri la data documentului
		@iesiriStocLaLuna int,	-- validare stocuri la luna documentului
		@gestiuniPfaraStoc varchar(1000),	-- lista de gestiuni de tip P fara stoc
		@dataStoc datetime 
	set @faraStoc=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='FARASTOC'),0)
	set @faraValidStoc=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='FARAVSTN'),0)
	set @iesiriStocLaData=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='IESSLAZI'),0)
	set @iesiriStocLaLuna=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='IESLUNCRT'),0)
	set @gestiuniPfaraStoc=','+isnull((select rtrim(val_alfanumerica) from par where Tip_parametru='GE' and Parametru='GESTPFST' and Val_logica=1),'')+','
	set @dataStoc='2999-12-31'
	if @iesiriStocLaData=1 set @dataStoc=@Data 
	if @iesiriStocLaLuna=1 set @dataStoc=dbo.eom(@Data) 

	declare @potscrie int 
	set @potscrie=0
	if left(cast(CONTEXT_INFO() as varchar),22)='modificarescriuintrare'
	begin
		set @potscrie=1
		--declare @msger varchar(120)
		--set @msger='?'+left(cast(CONTEXT_INFO() as varchar),22)+'!'+cast(@potscrie as char(1))
		--RAISERROR (@msger, 16, 1)
	end

	if @potscrie=0 and @faraStoc=0 and @faraValidStoc=0 and @cantitate<0.00001 
		and abs(@cantitate)>0.0009 -- daca variatia de cantitate nu este semnificativa sa nu validez stoc negativ (ex. daca modific ceva pe un doc.)
		and (@gestiuniPfaraStoc='' or charindex(','+rtrim(@Cod_gestiune)+',',@gestiuniPfaraStoc)=0)	-- sa nu se faca validarea pentru gestiunile de tip P, fara stoc
		and not exists (select 1 from stocuri where subunitate=@subunitate 
						and tip_gestiune=@tip_gestiune and cod_gestiune=@cod_gestiune and cod=@cod
						and cod_intrare=@cod_intrare and stoc+@cantitate>-0.00001 
						and (data<=@dataStoc or @tip='TE' and @tipm='I')) -- daca se limiteaza data stocului sa verifice si acest lucru
		and exists (select 1 from stocuri where subunitate=@subunitate 
						and tip_gestiune=@tip_gestiune and cod_gestiune=@cod_gestiune and cod=@cod 
						and cod_intrare=@cod_intrare) -- daca nu exista linia in stocuri, permitem documentul (FK pe pozdoc cu on delete cascade sterge linia din stocuri)
	begin
		declare @msgeroare varchar(500)
		set @msgeroare='validareStocNegativ: Documentul ar genera stoc negativ'
			+(case when (@iesiriStocLaData=1 or @iesiriStocLaLuna=1) and @Data>=@dataStoc then ' la data '+convert(char(10),@dataStoc,103) else '' end)
			+'. Doc:'+@Tip+' '+@Numar+' '+convert(char(10),@Data,103)+' Gestiune: '+rtrim(@cod_gestiune)+', cod: '+rtrim(@cod)+', cod intrare: '+rtrim(@cod_intrare)+'!'
		rollback transaction
		RAISERROR (@msgeroare, 16, 1)			
	end
end
