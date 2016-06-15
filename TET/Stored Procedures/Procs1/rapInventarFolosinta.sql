--***
create procedure rapInventarFolosinta(@dData datetime,
		@tipgest varchar(1),	--> tip gestiune: Depozit, Folosinta, (cusTodie)
		@ordonare varchar(1),	--> 'c'=cod, 'd'=denumire
		@grupare_cod_pret bit=0,
		@grupare varchar(1),	--> locm(=1), gestiune; nu functioneaza! (procedura nu aduce locuri de munca)
		@cCod varchar(50)=null, @cGestiune varchar(50)=null, @locm varchar(50)=null,
		@cont varchar(50)=null, 
		@contnom varchar(50)=null, @antetInventar int=null,
		@tippret varchar(1)='s',	--> s,t,v s=pret de stoc, t=f(tip gestiune), v=pret vanzare
		@categpret smallint=null,
		@faraDocumentCorectie int=0, -->Implicit cu documente de corectie
		@locatie varchar(200)=null
		)
as
begin
	set transaction isolation level read uncommitted
	declare @eroare varchar(500), @cGrupa varchar(13)

	set @eroare=''
	begin try
		exec rapInventarComparativa @dData=@dData , @cCod=@cCod, @tipgest=@tipgest,
			@cGestiune=@cGestiune, @locm=@locm, @cont=@cont, @ordonare=@ordonare,
			@grupare=@grupare, @antetInventar=@antetInventar, @grupare_cod_pret=@grupare_cod_pret,
			@tippret=@tippret, @categpret=@categpret, @locatie=@locatie, @contnom=@contnom, @standard=2
	end try
	begin catch
		set @eroare=ERROR_MESSAGE()+' (rapInventarFolosinta)'
	end catch
	if len(@eroare)>0 --raiserror(@eroare,16,1)
		select '<EROARE>' gestiune, @eroare den_gest 
end