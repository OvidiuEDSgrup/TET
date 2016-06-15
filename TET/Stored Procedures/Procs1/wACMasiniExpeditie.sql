
CREATE PROCEDURE wACMasiniExpeditie @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@searchtext varchar(300), @tert varchar(20), @subunitate char(9), @tertGen varchar(20)

	select
		@searchText = '%' + replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select 
		@searchText=ISNULL(replace(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'),' ', '%'), ''),   
		@tert=ISNULL(@parXML.value('(//@tertdelegat)[1]', 'varchar(20)'),@parXML.value('(//@tert)[1]', 'varchar(20)'))

	/* Daca nu am primit tertul=> caut masinile tertului general */
	if @parXML.value('(//@tertdelegat)[1]', 'varchar(20)') is null -- daca nu e selectat explicit un tert pt. delegati (cazul general)
	begin
		exec luare_date_par 'UC','TERTGEN',0,0,@tertGen OUTPUT
		if isnull(@tertGen,'')<>'' and ISNULL((select val_logica from par where Tip_parametru='AR' and Parametru='EXPEDITIE'),0)=0
			set @tert=@tertGen -- tertul setat este mai tare decat tertul documentului, in cazul setarii AR,EXPEDITIE = False 
	end

	select 
		rtrim(numarul_mijlocului) cod, RTRIM(ISNULL(NULLIF(descriere,''),rtrim(numarul_mijlocului))) denumire
	from masinexp 
	where furnizor=@tert 
		and rtrim(numarul_mijlocului) like '%'+@searchText+'%'
	for xml raw, root('Date')

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
