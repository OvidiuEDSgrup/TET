CREATE TABLE [dbo].yso_Garantii_corectii_furnizori
(
	[idPozADoc] INT NOT NULL 
		CONSTRAINT PK_yso_Garantii_corectii_furnizori 
			PRIMARY KEY CLUSTERED (idPozADoc) 
		CONSTRAINT FK_yso_Garant_cor_furn_PozADoc 
			FOREIGN KEY (idPozADoc) REFERENCES PozADoc(idPozADoc), 
    [idPozDoc] INT NOT NULL
		CONSTRAINT FK_yso_Garant_cor_furn_PozDoc 
			FOREIGN KEY (idPozDoc) REFERENCES Pozdoc(idPozDoc)
)

GO

CREATE UNIQUE INDEX [UQ_yso_Garant_cor_furn_IDPozDoc] ON [dbo].[yso_Garantii_corectii_furnizori] (idPozDoc)
