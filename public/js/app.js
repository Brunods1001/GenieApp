// This file is loaded by the browser when the page is loaded

// function that reloads page after 150 ms
function reloadPage() {
    setTimeout(function() {
        location.reload();
    }, 150);
}

// toggle completed class on todo_input class input elements on change
$(function () {
    $('input.todo_input[type="checkbox"]').on('change', function() {
        // redirect to homepage
        if (this.checked) {
            $(this).siblings('label').addClass('completed');
        } else {
            $(this).siblings('label').removeClass('completed');
        }
        // reloadPage();
    })
})

// On todo_input classed input elements, send post request and use response to check or uncheck
$(function () {
    $('input.todo_input[type="checkbox"]').on('change', function() {
        axios({
            method: 'post',
            url: '/todos/' + $(this).attr('value') + '/toggle',
            data: {}
        })
        .then(function(response) {
            $('#todo_' + response.data.todo.id.value).first().checked = response.data.completed;
        });
    });
});

// Make todo label editable on double click and update todo on enter key press
$(function() {
    $('li > label').on('dblclick', function() {
        $(this).attr('contenteditable', true);
    });

    $('li > label').on('keydown', function(event) {
        if (event.keyCode === 13) {
            $(this).removeAttr('contenteditable');
            axios({
                method: 'post',
                url: '/todos/' + $(this).data('todo-id') + '/update',
                data: { todo: $(this).html() }
            })
            .then(function(response) {
                $('label[data-todo-id="' + response.data.id.value + '"]')
                .first().html(response.data.todo);
            });
        } else if (event.keyCode === 27) {
            $(this).removeAttr('contenteditable');
            $(this).text($(this).attr('data-original'));
        }
    });
});

// Add invisible to button children of li elements on mouseenter and remove on mouseleave
$(function() {
    $('li').on('mouseenter', function() {
        $(this).children('button').removeClass('invisible');
    });

    $('li').on('mouseleave', function() {
        $(this).children('button').addClass('invisible');
    });
});

// On click of delete button, send delete request and remove todo from list
$(function() {
    $('button.delete').on('click', function() {
        // ask user to confirm delete
        if (confirm("Are you sure you want to delete this todo?") == true) {
            axios({
                method: 'post',
                url: '/todos/' + $(this).attr("value") + '/delete',
                data: {}
            })
            .then(function(response) {
                $('#todo_' + response.data.id.value).first().parent().remove();
            });
        };
    });
});