
/* procedura pentru populare macheta de inchidere luna */
create procedure wOPInchidereLuna_p @sesiune varchar(50), @parXML xml 
as  
	declare 
		@lunainch int, @anulinch int, @lunabloc int, @anulbloc int

	SELECT TOP 1@lunainch=isnull(val_numerica,1) from par where tip_parametru='GE' and parametru='LUNAINC'
	SELECT TOP 1 @anulinch=isnull(val_numerica,1901) from par where tip_parametru='GE' and	parametru='ANULINC'
	SELECT TOP 1 @lunabloc=isnull(val_numerica,1) from par where tip_parametru='GE' and parametru='LUNABLOC'
	SELECT TOP 1 @anulbloc=isnull(val_numerica,1901) from par where tip_parametru='GE' and parametru='ANULBLOC'
	
	if @anulbloc=0
		select @lunabloc=@lunainch, @anulbloc=@anulinch
	select
		@anulbloc=(case when @lunabloc=12 then @anulbloc+1 else @anulbloc end),
		@lunabloc=(case when @lunabloc=12 then 1 else @lunabloc+1 end)

	select @lunabloc as luna, @anulbloc as anul	for xml raw, root('Date')
