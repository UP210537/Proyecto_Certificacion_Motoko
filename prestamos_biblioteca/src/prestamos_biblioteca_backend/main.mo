import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

actor LibrarySystem {
    //Definición de usuarios
    type User = {
        id: Nat;
        name: Text;
        quantity: Int; 
    };

    //Definición de libros
    type Book = {
        id: Nat;
        title: Text;
        author: Text;
        available: Bool;
        quantity: Int;  
    };

    var users: [User] = [];
    var books: [Book] = [];
    var nextUserId: Nat = 0;
    var nextBookId: Nat = 0;

    //Obtener usuario por ID
    public func getUserById(userId: Nat): async ?User {
        Array.find<User>(users, func(user) { user.id == userId });
    };

    //Obtener libro por ID
    public func getBookById(bookId: Nat): async ?Book {
        Array.find<Book>(books, func(book) { book.id == bookId })
    };

    //Función: Agregar un usuario
    public func addUser(name: Text): async User {
        let newUser = {
            id = nextUserId;
            name = name;
            quantity = 0;
        };
        users := Array.append(users, [newUser]);
        nextUserId += 1;
        return newUser;
    };

    //Función: Eliminar un usuario
    public func removeUser(userId: Nat): async Bool {
        users := Array.filter<User>(users, func(user) { user.id != userId });
        if (userId == nextUserId - 1) {
            nextUserId -= 1;
        };
        true;
    };

    //Función: Agregar un libro
    public func addBook(title: Text, author: Text, quantity: Nat): async Book {
        let newBook = {
            id = nextBookId;
            title = title;
            author = author;
            available = true;  // Por defecto está disponible
            quantity = quantity;
        };
        books := Array.append(books, [newBook]);
        nextBookId += 1;
        return newBook;
    };

    //Función: Disponibilidad
    public func isBookAvailable(bookId: Nat): async Bool {
        let book = await getBookById(bookId);
        if (book == null) {
            return false;
        };
        return true;
    };

    //Función: Préstamo de libro
    public func borrowBook(bookId: Nat, userId: Nat): async Bool {
        let bookOpt = await getBookById(bookId);
        let userOpt = await getUserById(userId);
        switch (bookOpt, userOpt) {
            case (?book, ?user) {
                if (book.quantity > 0) {
                    let newBook = {
                        id = book.id;
                        title = book.title;
                        author = book.author;
                        available = book.quantity > 1;  //Actualiza la disponibilidad
                        quantity = book.quantity - 1;
                    };
                    books := Array.map<Book, Book>(books, func(b) {
                        if (b.id == bookId) {
                            newBook
                        } else {
                            b
                        }
                    });
                    //Actualiza la cantidad de libros prestados por el usuario
                    let newUser = {
                        id = user.id;
                        name = user.name;
                        quantity = user.quantity + 1;
                    };
                    users := Array.map<User, User>(users, func(u) {
                        if (u.id == userId) {
                            newUser
                        } else {
                            u
                        }
                    });
                    Debug.print("Libro retirado por el usuario " # user.name # ". Cantidad actual: " # Int.toText(newBook.quantity));
                    //Agrega un registro de préstamo
                    bookBorrows := Array.append(bookBorrows, [(bookId, userId)]);
                    return true;
                } else {
                    return false;
                };
            };
            case _ {
                return false;
            };
        }
    };
    
    var bookBorrows: [(Nat, Nat)] = [];
    //Función: Devolución de libro
    public func returnBook(bookId: Nat, userId: Nat): async Bool {
        let bookOpt = await getBookById(bookId);
        let userOpt = await getUserById(userId);
        switch (bookOpt, userOpt) {
            case (?book,?user) {
                //Verifica si el usuario que devuelve el libro es el mismo que el que lo pidió
                let borrowRecord = Array.find<(Nat, Nat)>(bookBorrows, func((bid, uid)) { bid == bookId and uid == userId });
                if (borrowRecord!= null) {
                    let newBook = {
                        id = book.id;
                        title = book.title;
                        author = book.author;
                        available = true;  //Actualiza la disponibilidad
                        quantity = book.quantity + 1;
                    };
                    books := Array.map<Book, Book>(books, func(b) {
                        if (b.id == bookId) {
                            newBook
                        } else {
                            b
                        }
                    });
                    //Actualiza la cantidad de libros prestados por el usuario
                    let newUser = {
                        id = user.id;
                        name = user.name;
                        quantity = user.quantity - 1;
                    };
                    users := Array.map<User, User>(users, func(u) {
                        if (u.id == userId) {
                            newUser
                        } else {
                            u
                        }
                    });
                    //Elimina el registro de préstamo
                    bookBorrows := Array.filter<(Nat, Nat)>(bookBorrows, func((bid, uid)) { bid!= bookId or uid!= userId });
                    Debug.print("Libro devuelto por el usuario " # user.name # ". Cantidad actual: " # Int.toText(newBook.quantity));
                    return true;
                } else {
                    Debug.print("Error: El usuario no tiene permiso para devolver este libro.");
                    return false;
                };
            };
            case _ {
                return false;
            };
        }
    };
}