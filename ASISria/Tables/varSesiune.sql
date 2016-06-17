CREATE TABLE [dbo].[varSesiune] (
    [sesiune]    VARCHAR (25) NOT NULL,
    [detaliiXML] XML          NULL,
    CONSTRAINT [PK_varSesiune] PRIMARY KEY CLUSTERED ([sesiune] ASC),
    FOREIGN KEY ([sesiune]) REFERENCES [dbo].[sesiuniRIA] ([token]) ON DELETE CASCADE ON UPDATE CASCADE
);

