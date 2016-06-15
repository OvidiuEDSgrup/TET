
create procedure wACDocCodBare @sesiune varchar(50), @parXML xml
as

	declare @search varchar(100), @exact varchar(100), @tip_doc varchar(20), @data datetime


	set @search='%'+isnull(replace(@parXML.value('(/*/@searchText)[1]','varchar(1000)'),' ','%'),'%')+'%'
	set @tip_doc=@parXML.value('(/*/@tip_filtrare)[1]','varchar(20)')
	set @data=@parXML.value('(/*/@data)[1]','datetime')

	IF @tip_doc in ('RM','TE','AP','AI','AE')
		select top 100
			rtrim(numar) as cod, RTRIM(numar)+'-'+convert(varchar(10), data, 103) denumire
		from doc where Subunitate='1' and Tip=@tip_doc and DATEDIFF(MONTH,Data,getdate())<=6 and ((@tip_doc='TE' and numar like 'MP%') OR @tip_doc<>'TE')
		and numar like @search and doc.data=@data
		for xml raw, root('Date')

	else if @tip_doc ='ST'
		exec wACGestiuni @sesiune=@sesiune, @parXML=@parXML
		else if @tip_doc='CP'
			exec wACCategPret @sesiune=@sesiune, @parXML=@parXML
			else if @tip_doc='GR'
				exec wACGrupe @sesiune=@sesiune, @parXML=@parXML
				else 
					select replace(@search,'%','') cod, replace(@search,'%','') denumire for xml raw, root('Date')
